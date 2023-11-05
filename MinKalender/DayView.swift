import SwiftUI
import EventKit

struct DayView: View {
    
    @State private var slideOverHeight: CGFloat = 0
    @State var currentTimePosition: CGFloat = 0
    @ObservedObject var dailyTaskData: DailyTaskData
    @Binding var dailyTasks: Set<String>
    @Binding var tasksForDay: [TaskInfo]
    @Binding var userWantToPrintTime: Bool
    
    //    var userWantToPrintTime: Bool = true
    //    @State var eventsForDay = MinaEvent.fetchCalendarsAndEventsForDate() // When testing in preview
    
    //@State var taskCalendar: String = "Hem"
    var timeUpdateInterval: TimeInterval = 30
    
    var eventTime: String? // Eventuell tid
    var today = Date()
    let calendar = Calendar.autoupdatingCurrent
    
    func userWantToPrintTime(_ taskInfo: TaskInfo) -> String? {
        if userWantToPrintTime {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: taskInfo.task.startDate)
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
    
    
    //    private func updateTasksForSelectedCalendar() {
    //            tasksForDay = sortedTaskInfos.filter { taskInfo in
    //                let taskDate = calendar.startOfDay(for: taskInfo.event.startDate)
    //                return taskDate == today && taskInfo.calendarName == selectedCalendar
    //            }.enumerated().map { (index, taskInfo) in
    //                return TaskInfo(event: taskInfo.event, calendarName: taskInfo.event.calendar.title, stackingNumber: index)
    //            }
    //        }
//
//    private func filteredTaskInfos() -> [TaskInfo] {
//            let calendar = Calendar.current
//            let today = calendar.startOfDay(for: Date())
//    return sortedTaskInfos.filter { taskInfo in
//        let taskDate = calendar.startOfDay(for: taskInfo.event.startDate)
//        return taskDate == today && taskInfo.calendarName == dailyTasks
//    }.enumerated().map { (index, taskInfo) in
//        return TaskInfo(event: taskInfo.event, calendarName: taskInfo.event.calendar.title, stackingNumber: index)
//    }
//  }
    
    private var sortedTaskInfos: [TaskInfo] {
        return tasksForDay.sorted { $0.task.startDate < $1.task.startDate }
    }
    
    private var filteredTaskInfos: [TaskInfo] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return sortedTaskInfos.filter { taskInfo in
            let taskDate = calendar.startOfDay(for: taskInfo.task.startDate)
            return taskDate == today && dailyTaskData.dailyTasks.contains(taskInfo.calendarName)
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
                    .overlay(
                        VStack(alignment: .center) {
                            HStack(alignment: .top) {
                                Spacer()
                                Text("⋯")
                                    .font(.custom("STIXGeneral-Bold", size: 28))
                                    .foregroundColor(Color(UIColor.systemGray))
                                    .frame(alignment: .center)
                                    .position(x: geometry.size.width / 2 - 20, y: -25)
                                    .padding()
                                
                                Spacer()
                                Picker("Select Calendar", selection: $dailyTasks) {
                                    ForEach(Array(dailyTaskData.dailyTasks), id: \.self) { calendarName in
                                        Text(calendarName)
                                        
                                    }
                                }
                                .foregroundColor(Color.black)
                                .padding()
                                .onChange(of: dailyTasks) { newTasks in
                                    print("nu händer nåt")
                                    tasksForDay = filteredTaskInfos
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    )
                    
                    
                    ZStack {
                        ForEach(filteredTaskInfos, id: \.task.eventIdentifier) { taskInfo in
                            // Also give padding 20 bottom to this part to correct time, or find the fault elsewhere
                            ZStack {
                                let stackNr = (taskInfo.stackingNumber ?? 0) * 17
                                if let timeToPrint = userWantToPrintTime(taskInfo) {
                                    let yPos = timeToPixel(time: taskInfo.task.startDate) + CGFloat(stackNr) + 9
                                    Text("\(timeToPrint) - \(taskInfo.task.title)")
                                        .textCase(.uppercase)
                                        .foregroundColor(Color.secondary.opacity(1))
                                        .font(Font.system(size: 12, weight: .bold))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .position(x: 0, y: yPos * 0.915) // This is to compensate text height offset
                                        .padding(0)
                                } else {
                                    let yPos = timeToPixel(time: taskInfo.task.startDate) + CGFloat(stackNr) + 9
                                    Text("\(taskInfo.task.title)")
                                        .textCase(.uppercase)
                                        .foregroundColor(Color.secondary.opacity(1))
                                        .font(Font.system(size: 12, weight: .bold))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .position(x: 0, y: yPos * 0.915) // This is to compensate text height offset
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
                        .offset(y: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(EdgeInsets(top: -20, leading: 0, bottom: -20, trailing: 0))
                )
                .overlay(
                    TriangularIndicator()
                        .offset(x: 0, y: currentTimePosition)
                )
            } // This is geometryReader
            .overlay( // Outer border
                (RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(UIColor.systemGray), lineWidth: 0.7))
                    .background(Color.clear)
                    .padding(EdgeInsets(top: -20, leading: 0, bottom: -20, trailing: 0))
            )
        }
        .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
    }
}



//
//struct Previews_DayView_Previews: PreviewProvider {
//    static var previews: some View {
//        DayView()
//.previewInterfaceOrientation(.portraitUpsideDown)
//    }
//}
