

import SwiftUI


struct ContentView: View {
    
    @EnvironmentObject var model: Model
    
    var body: some View {
        return VStack {
            
            
            Spacer()
            
            
            Group {
                
                // Price
                let currencySign = self.model.targetCurrencySign()
                Text(verbatim: "\(currencySign)\(self.model.askPrice)")
                    .font(Font.system(size: 23.0, weight: .bold, design: .monospaced))
                
                // Error Message
                if self.model.errorMessage != "" {
                    Text(verbatim: self.model.errorMessage)
                        .font(Font.caption.weight(.semibold))
                }
                
                
            }
            .foregroundColor(Color.accentColor)
            .help(self.model.serverResponseString) // JSON String
            
            
            Spacer()
            
            
            HStack {
                
                let currencyCodes = Model.CurrencyCode.allCases
                
                Picker(selection: self.$model.leftHandedCurrency, label: Text("left_handed_currency")) {
                    ForEach(0..<currencyCodes.count, id: \.self) {
                        index in
                        let currencyCode = currencyCodes[index]
                        Text(verbatim: currencyCode.rawValue)
                            .tag(currencyCode)
                        
                    }
                }
                
                Picker(selection: self.$model.rightHandedCurrency, label: Text("right_handed_currency")) {
                    ForEach(0..<currencyCodes.count, id: \.self) {
                        index in
                        let currencyCode = currencyCodes[index]
                        Text(verbatim: currencyCode.rawValue)
                            .tag(currencyCode)
                        
                    }
                }
                
                Button(action: {
                    self.model.requestData()
                }, label: {
                    Text("request_data")
                })
                
            }
            .labelsHidden()
            
        }
        .padding([.horizontal, .bottom], 24.0)
        .frame(height: 180.0)
        .navigationTitle("Kraken API — \(self.model.serverStatusCode)")
        
    }
    
    
}


// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Model())
    }
}
