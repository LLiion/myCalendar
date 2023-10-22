import SwiftUI
import EventKit

struct DayView: View {
    
    @State private var slideOverHeight: CGFloat = 0
    @State var currentTimePosition: CGFloat = 0

    @Binding var eventsForDay: [EventInfo]
    @Binding var userWantToPrintTime: Bool
//    var userWantToPrintTime: Bool = true
//    @State var eventsForDay = MinaEvent.fetchCalendarsAndEventsForDate() // When testing in preview
    
    var timeUpdateInterval: TimeInterval = 30
    
    var eventTime: String? // Eventuell tid

    func userWantToPrintTime(_ eventInfo: EventInfo) -> String? {
        if userWantToPrintTime {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: eventInfo.event.startDate)
        }
        return nil
    }
    
    private var timeIntervals: [String] {
        var intervals = [String]()
        let calendar = Calendar.current
        var currentDate = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!

        while currentDate <= calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date())! {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            intervals.append(dateFormatter.string(from: currentDate))
            currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate)!
        }
        return intervals
    }
    
    private var sortedEventInfos: [EventInfo] {
            return eventsForDay.sorted { $0.event.startDate < $1.event.startDate }
    }
    
    private var filteredEventInfos: [EventInfo] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return sortedEventInfos.filter { eventInfo in
            let eventDate = calendar.startOfDay(for: eventInfo.event.startDate)
            return eventDate == today && eventInfo.calendarName == "Fredrik hem"
        }.enumerated().map { (index, eventInfo) in
            return EventInfo(event: eventInfo.event, calendarName: eventInfo.event.calendar.title, stackingNumber: index)
        }
    }
    
    func timeToPixel(time: Date) -> CGFloat {
        let calendar = Calendar.current
        let startOfDay = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
        let endOfDay = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
        
        let totalTimeInterval = endOfDay.timeIntervalSince(startOfDay)
        let currentTimeInterval = time.timeIntervalSince(startOfDay)
        
        let screenHeight = slideOverHeight
        let pixelsPerHour = screenHeight / CGFloat(totalTimeInterval / 3600)
        
        return CGFloat((currentTimeInterval / 3600) * pixelsPerHour)
    }
    
    struct TriangularIndicator: View {
        var body: some View {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 10, y: 5))
                path.addLine(to: CGPoint(x: 0, y: 10))
                path.addLine(to: CGPoint(x: 0, y: 0))
            }
            .fill(Color(UIColor.systemGray))
        }
    }

    var body: some View {
        ZStack {
        GeometryReader { geometry in
        ZStack {
            ForEach(7...22, id: \.self) { hour in
                ZStack {
                let time = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
                    Text("\(hour):00")
                    .offset(x: 15, y: (timeToPixel(time: time)))
                    .foregroundColor(Color.gray)
                    .padding(0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: slideOverHeight, alignment: .topLeading)
            .frame(height: slideOverHeight)
            
            ZStack {
                ForEach(filteredEventInfos, id: \.event.eventIdentifier) { eventInfo in
                    // Also give padding 20 bottom to this part to correct time, or find the fault elsewhere
                    ZStack {
                    let stackNr = (eventInfo.stackingNumber ?? 0) * 17
                    if let timeToPrint = userWantToPrintTime(eventInfo) {
                        let yPos = timeToPixel(time: eventInfo.event.startDate) + CGFloat(stackNr) + 9
                            Text("\(timeToPrint) - \(eventInfo.event.title)")
                                .textCase(.uppercase)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .position(x: 0, y: yPos * 0.915) // This is to compensate text height offset
                                .padding(0)
                        } else {
                            Text("\(eventInfo.event.title)")
                                .textCase(.uppercase)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .position(x: 0, y: timeToPixel(time: eventInfo.event.startDate) + CGFloat(stackNr))
                                .padding(0)
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 60, bottom: 0, trailing: 0))
                }
                .frame(maxWidth: .infinity, maxHeight: slideOverHeight, alignment: .topLeading)
                
                .offset(x: 60, y: 10)
            }
            .frame(maxWidth: geometry.size.width * 0.8, maxHeight: slideOverHeight, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: slideOverHeight, alignment: .topLeading)
        .onAppear {
            slideOverHeight = (geometry.size.height)
            currentTimePosition = timeToPixel(time: Date())
            Timer.scheduledTimer(withTimeInterval: timeUpdateInterval, repeats: true) { _ in
                withAnimation {
                    currentTimePosition = timeToPixel(time: Date())
                }
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(UIColor.systemBlue).opacity(0.9), Color(UIColor.systemBackground).opacity(0)]),
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: (currentTimePosition / slideOverHeight) * 1.5)
                )
            .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(EdgeInsets(top: -20, leading: 0, bottom: -20, trailing: 0))
        )
        .overlay(
            TriangularIndicator()
                .offset(x: 0, y: currentTimePosition)
        )
    }
    .overlay( // Outer border
        (RoundedRectangle(cornerRadius: 10)
        .stroke(Color(UIColor.systemGray), lineWidth: 0.7))
        .background(Color.clear)
        .padding(EdgeInsets(top: -20, leading: 0, bottom: -20, trailing: 0))
        )
    .overlay(
        VStack {
            HStack {
                Spacer()
        Text("⋯") // Refuses to be centered. Later perhaps give it a white background för UI recognition.
            .font(.custom("STIXGeneral-Bold", size: 28))
            .foregroundColor(Color(UIColor.systemGray))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .position(y: -10)
            .padding(0)
                Spacer()
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        Spacer()
        }
    )
    

            
        } // This is geometryReader
        .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
        
        
    }
}



//
//struct Previews_DayView_Previews: PreviewProvider {
//    static var previews: some View {
//        DayView()
//    }
//}
