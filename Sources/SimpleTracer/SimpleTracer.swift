//
//  SimpleTracer.swift
//  SimpleTracer
//
//  Created by Wang Xingbin on 2018/10/18.
//  Copyright © 2018 Beary Innovative. All rights reserved.
//

import Foundation
import os

public protocol SimpleTracerLogger: AnyObject {
    func logTrace(_ step: TraceStep)
}

public class SimpleTracer: NSObject {
    
    public var host: String
    
    private var pinger: SimplePing?
    
    private var ipAddress: String?
    private var icmpSrcAddress: String?
    
    private var currentTTL: Int?
    private var packetCountPerTTL: Int?
    private var maxTraceTTL: Int = 30
    private var sendSequence: UInt16?
    
    private var startDate: Date?
    private var sendTimer: Timer?
    private var sendTimeoutTimer: Timer?
    
    private(set) var result: [TraceStep] = []
    private var logger: ((TraceStep) -> Void)?
    
    public init(host: String) {
        self.host = host
        super.init()
    }
    
    private static var _current: SimpleTracer?
    
    @discardableResult
    public static func trace(host: String, maxTraceTTL: Int = 30, logger: ((TraceStep) -> Void)?) -> SimpleTracer {
        let tracer = SimpleTracer(host: host)
        tracer.logger = logger
        tracer.maxTraceTTL = maxTraceTTL
        
        _current = tracer
        _current?.start()
        
        return _current!
    }
    
    public func start() {
        pinger = SimplePing(hostName: host)
        pinger?.delegate = self
        pinger?.start()
    }
    
    public func stop() {
        sendTimer?.invalidate()
        sendTimer = nil
        sendTimeoutTimer?.invalidate()
        sendTimeoutTimer = nil
        
        pinger?.stop()
        pinger = nil
    }
}

public enum TraceStep {
    case start(host: String, ip: String, ttl: Int)
    case router(step: UInt16, ip: String, duration: Int)
    case routerDoesNotRespond(step: UInt16)
    case finished(step: UInt16, ip: String, latency: Int)
    case failed(error: String)
}

// MARK: - Private
private extension SimpleTracer {
    func appendResult(step: TraceStep) {
        self.result.append(step)
        logger?(step)
    }
    
    func sendPing() -> Bool {
        self.currentTTL! += 1
        if self.currentTTL! > maxTraceTTL {
            stop()
            
            return false
        }
        
        sendPing(withTTL: self.currentTTL!)
        return true
    }
    
    func sendPing(withTTL ttl: Int) {
        packetCountPerTTL = 0
        
        pinger?.setTTL(Int32(ttl))
        pinger?.send()
        
        sendTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(checkSingleRoundTimeout), userInfo: nil, repeats: false)
    }
    
    func invalidSendTimer() {
        sendTimer?.invalidate()
        sendTimer = nil
    }
    
    @objc
    func checkSingleRoundTimeout() {
        appendResult(step: .routerDoesNotRespond(step: sendSequence!))
        _ = sendPing()
    }
}

// MARK: Utilities from: https://developer.apple.com/library/archive/samplecode/SimplePing/
extension SimpleTracer {
    
    /// Returns the string representation of the supplied address.
    ///
    /// - parameter address: Contains a `(struct sockaddr)` with the address to render.
    ///
    /// - returns: A string representation of that address.
    
    static func displayAddressForAddress(address: NSData) -> String {
        var hostStr = [Int8](repeating: 0, count: Int(NI_MAXHOST))
        
        let success = getnameinfo(address.bytes.assumingMemoryBound(to: sockaddr.self),
                                  socklen_t(address.length),
                                  &hostStr,
                                  socklen_t(hostStr.count),
                                  nil,
                                  0,
                                  NI_NUMERICHOST
        ) == 0
        let result: String
        if success {
            result = String(cString: hostStr)
        } else {
            result = "?"
        }
        return result
    }
}

// MARK: - SimplePingDelegate
extension SimpleTracer: SimplePingDelegate {
    public func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data) {
        ipAddress = SimpleTracer.displayAddressForAddress(address: address as NSData)
        let msg = "\(ipAddress ?? "* * *")"
        os_log(.debug, "Start tracing \(self.host): \(msg)")
        NSLog(msg)
        appendResult(step: .start(host: host, ip: msg, ttl: currentTTL!))
        
        currentTTL = 1
        sendPing(withTTL: currentTTL!)
    }
    
    public func simplePing(_ pinger: SimplePing, didFailWithError error: Error) {
        let msg = error.localizedDescription
        os_log(.debug, "Failed to trace \(self.host): \(msg)")
        appendResult(step: .failed(error: msg))
        stop()
    }
    
    public func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
        os_log(.debug, "#\(sequenceNumber) Data sent, size=\(packet.count)")
        sendSequence = sequenceNumber
        startDate = Date()
    }
    
    public func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error) {
        let msg = error.localizedDescription
        os_log(.debug, "#\(sequenceNumber) send \(packet) failed: \(msg)")
        appendResult(step: .failed(error: msg))
    }
    
    public func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
        invalidSendTimer()
        guard let startDate = startDate else { return }
        
        let interval = Date().timeIntervalSince(startDate)
        sendTimeoutTimer?.invalidate()
        
        // Complete
        guard sequenceNumber == sendSequence, let ipAddress = ipAddress else { return }
        let msg = "#\(sequenceNumber) reach the destination \(ipAddress), trace completed. It's simple! Right?\n"
        os_log(.debug, "\(msg)")
        appendResult(step: .finished(step: sequenceNumber, ip: ipAddress, latency: Int(interval * 1000)))
        
        stop()
    }
    
    public func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
        assert(startDate != nil)
        let interval = Date().timeIntervalSince(startDate!)
        
        let srcAddr = pinger.srcAddr(inIPv4Packet: packet)
        if packetCountPerTTL == 0 {
            icmpSrcAddress = srcAddr
            self.packetCountPerTTL! += 1
            let msg = interval * 1000
            os_log(.debug, "\(String(format: "#\(sendSequence!)) \(srcAddr)     %0.3lf ms", msg))")
            appendResult(step: .router(step: sendSequence!, ip: srcAddr, duration: Int(msg)))
        } else {
            self.packetCountPerTTL! += 1
        }
        
        if packetCountPerTTL == 3 {
            invalidSendTimer()
            _ = sendPing()
        }
    }
}
