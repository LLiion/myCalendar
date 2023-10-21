import SwiftUI
import EventKit

struct DayView: View {
    
    @State private var slideOverHeight: CGFloat = 0
    @State var currentTimePosition: CGFloat = 0
    @Binding var eventsForDay: [EventInfo]
    @Binding var userWantToPrintTime: Bool

    //@State var eventsForDay = MinaEvent.fetchCalendarsAndEventsForDate() // When testing in preview
    
    var timeUpdateInterval: TimeInterval = 30
    
    var eventTime: String? // Eventuell tid

    func userWantToPrintTime(_ eventInfo: EventInfo) -> String? {
        if userWantToPrintTime {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short // Här använder vi .short för stilen .time
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
            return eventDate == today //&& eventInfo.calendarName == "Hem"
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
            Text("⋯")
                .font(.custom("STIXGeneral-Bold", size: 28))
                .foregroundColor(Color(UIColor.systemGray))
                .padding(-30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                    
                    ZStack {
                        if let timeToPrint = userWantToPrintTime(eventInfo) {
                        Text("\(timeToPrint) - \(eventInfo.event.title)")
                            .position(x: 120, y: timeToPixel(time: eventInfo.event.startDate))
                            .padding(0)
                        } else {
                            Text("\(eventInfo.event.title)")
                                .position(x: 120, y: timeToPixel(time: eventInfo.event.startDate))
                                .padding(0)
                        }
                    }
                }
                .frame(height: slideOverHeight)
                .padding(0)
            }
            .frame(maxWidth: .infinity, maxHeight: slideOverHeight)
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
    .overlay(
        (RoundedRectangle(cornerRadius: 10)
        .stroke(Color(UIColor.systemGray), lineWidth: 0.7))
        .background(Color.clear)
            .padding(EdgeInsets(top: -20, leading: 0, bottom: -20, trailing: 0))
        )
    }
        .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
    }
}

//struct Previews_DayView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            DayView()
//.previewInterfaceOrientation(.landscapeRight)
//        }
//    }
//}
