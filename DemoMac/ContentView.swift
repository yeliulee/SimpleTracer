//
//  ContentView.swift
//  DemoMac
//
//  Created by Vitalii Parovishnyk on 31.01.2022.
//  Copyright © 2022 Beary Innovative. All rights reserved.
//

import SwiftUI
import SimpleTracer

struct ContentView: View {
    @State var traceLog: String = ""
    
    var body: some View {
        VStack {
            Button("Start") {
                SimpleTracer.trace(host: "apple.com", maxTraceTTL: 15) { (result) in
                    traceLog += "\(result.info())\n"
                    
                    print(result)
                }
            }
            
            Text(traceLog)
        }.padding()
            .frame(width: 330, height: 400, alignment: .top)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
