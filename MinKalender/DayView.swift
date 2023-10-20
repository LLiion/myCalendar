import SwiftUI
import EventKit

struct DayView: View {
    
    @State private var rotatedHeight: CGFloat = 0
    @State var currentTimePosition: CGFloat = 0
    //@Binding var eventsForDay: [EventInfo]
    @State var eventsForDay = MinaEvent.fetchCalendarsAndEventsForDate()
    
    var timeUpdateInterval: TimeInterval = 30
    
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
            return eventDate == today && eventInfo.calendarName == "Hem"
        }
    }
    
    func timeToPixel(time: Date) -> CGFloat {
        let calendar = Calendar.current
        let startOfDay = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
        let endOfDay = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
        
        let totalTimeInterval = endOfDay.timeIntervalSince(startOfDay)
        let currentTimeInterval = time.timeIntervalSince(startOfDay)
        
        let screenHeight = rotatedHeight
        let pixelsPerHour = screenHeight / CGFloat(totalTimeInterval / 3600)
        
        return CGFloat((currentTimeInterval / 3600) * pixelsPerHour)
    }
    
    struct TriangularIndicator: View {
        var body: some View {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 15, y: 10))
                path.addLine(to: CGPoint(x: -15, y: 30))
                path.addLine(to: CGPoint(x: 0, y: 00))
            }
            .fill(Color(UIColor.systemGray))
        }
    }

    var body: some View {
        GeometryReader { geometry in
        ZStack {
            Text("⋯")
                .font(.custom("STIXGeneral-Bold", size: 28))
                .foregroundColor(Color(UIColor.systemGray))
                .padding(0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            VStack {

                HStack {
                    VStack {
                        ForEach(7...22, id: \.self) { hour in
                            
                            Text("Här")
                            
//
//                            let time = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
//                                Text("\(hour):00")
//                                .offset(x: 0, y: timeToPixel(time: time) * rotatedHeight)
//                                .foregroundColor(Color.gray)
                        }
                    }
                    .padding()
                    .frame(maxWidth: 100, maxHeight: rotatedHeight, alignment: .top)
                    .frame(height: rotatedHeight)
                }
                VStack {
                    ForEach(filteredEventInfos, id: \.event.eventIdentifier) { eventInfo in
                        let atTime = ((timeToPixel(time: eventInfo.event.startDate)) / rotatedHeight)
                        ZStack {
                            Text("\(eventInfo.event.startDate, style: .time) - \(eventInfo.event.title)")
                                .position(x: 50, y: atTime)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: rotatedHeight, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(Color(UIColor.systemBackground))
        )
        .onAppear {
            rotatedHeight = (geometry.size.height * 0.9) * 1.1
            currentTimePosition = timeToPixel(time: Date())
            Timer.scheduledTimer(withTimeInterval: timeUpdateInterval, repeats: true) { _ in
                withAnimation {
                    currentTimePosition = timeToPixel(time: Date())
                }
            }
        }
        .overlay(
            LinearGradient(
                gradient: Gradient(colors: [Color(UIColor.blue).opacity(0.7), Color.clear]),//Color(UIColor.systemBlue).opacity(0.6), Color(UIColor.systemBlue).opacity(0.6), Color(UIColor.systemBlue).opacity(0.4), Color(UIColor.systemBackground).opacity(0)]),
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: currentTimePosition / rotatedHeight)
                )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        )
        
        .overlay(
            TriangularIndicator()
                .offset(x: 0, y: currentTimePosition)
        )
    }
    .overlay(
        RoundedRectangle(cornerRadius: 10)
        .stroke(Color.gray, lineWidth: 0.5)
        .background(Color.clear)
        )
    }
}

struct Previews_DayView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DayView()
        }
    }
}
