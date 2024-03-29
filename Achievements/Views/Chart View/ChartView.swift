//
//  ChartView.swift
//  Achievements
//
//  Created by Yuki Takahashi on 23/01/2021.
//

import SwiftUI
import CoreData

extension AnyTransition {
    static var moveAndFade: AnyTransition {
            let insertion = AnyTransition.move(edge: .trailing)
                .combined(with: .opacity)
            let removal = AnyTransition.scale
                .combined(with: .opacity)
            return .asymmetric(insertion: insertion, removal: removal)
        }
}

struct ChartView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var modelData: ModelData
    @EnvironmentObject var categoryFilter: CategoryFilter
    @State private var activeSheet: ActiveSheetNavBar?
    
    @State private var showWeeklyDetail = true
    @State private var showMonthlyDetail = true

    let calendar = Calendar.current
    
    /* Today and Yesterday Part*/
    @FetchRequest(entity: Log.entity(),
                  sortDescriptors: [],
                  predicate: NSCompoundPredicate(type: .or, subpredicates: [
                      NSPredicate(format: "activityDate >= %@", Date().addingTimeInterval(-60*60*24*2) as CVarArg),
                      NSPredicate(format: "NOT (isRoutine == true AND isToDo == true)")
                  ])
    ) var currentAdhocLogs: FetchedResults<Log>
    
    @FetchRequest(entity: Log.entity(),
                  sortDescriptors: [],
                  predicate: NSPredicate(format: "isRoutine == true AND isToDo == true")
    ) var allRoutineLogs: FetchedResults<Log>
    
    var logsTodayDone: [Log] {
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
        return categoryFilter.filterLogs(currentAdhocLogs).filter { log in
            (log.wrappedActivityDate >= todayStart) &&
                (log.wrappedActivityDate < tomorrowStart) &&
                (log.isToDo == false)
        }
    }
    var logsYesterdayDone: [Log] {
        let todayStart = calendar.startOfDay(for: Date())
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) ?? Date()
        return categoryFilter.filterLogs(currentAdhocLogs).filter { log in
            (log.wrappedActivityDate >= yesterdayStart) &&
                (log.wrappedActivityDate < todayStart) &&
                (log.isToDo == false)
        }
    }
    var adhocLogsTodayToDo: [Log] {
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
        return categoryFilter.filterLogs(currentAdhocLogs).filter { log in
            (log.wrappedActivityDate >= todayStart) &&
                (log.wrappedActivityDate < tomorrowStart) &&
                (log.isToDo == true)
        }
    }
    var adhocLogsYesterdayToDo: [Log] {
        let todayStart = calendar.startOfDay(for: Date())
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) ?? Date()
        return categoryFilter.filterLogs(currentAdhocLogs).filter { log in
            (log.wrappedActivityDate >= yesterdayStart) &&
                (log.wrappedActivityDate < todayStart) &&
                (log.isToDo == true)
        }
    }
    var routineLogsToday: [Log] {
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
        return categoryFilter.filterLogs(allRoutineLogs).filter { log in
            (log.wrappedActivityDate < tomorrowStart) &&
                (logsTodayDone.firstIndex(where: { $0.routineLogId == log.id }) == nil)
        }
    }
    var routineLogsYesterday: [Log] {
        let todayStart = calendar.startOfDay(for: Date())
        return categoryFilter.filterLogs(allRoutineLogs).filter { log in
            (log.wrappedActivityDate < todayStart) &&
                (logsYesterdayDone.firstIndex(where: { $0.routineLogId == log.id }) == nil)
        }
    }
    var logsTodayToDo: [Log] {
        adhocLogsTodayToDo + routineLogsToday
    }
    var logsYesterdayToDo: [Log] {
        adhocLogsYesterdayToDo + routineLogsYesterday
    }

    /* Weekly and Monthly Part*/
    @FetchRequest(entity: Log.entity(),
                  sortDescriptors: [],
                  predicate: NSCompoundPredicate(type: .and, subpredicates: [
                      NSPredicate(format: "activityDate >= %@", Date().addingTimeInterval(-60*60*24*60) as CVarArg),
                      NSPredicate(format: "isToDo == false")
                  ])
    ) var historicalLogs: FetchedResults<Log>
    
    var logsByWeek: Dictionary<String, [Log]> {
        Dictionary(grouping: categoryFilter.filterLogs(historicalLogs)) { (log) -> String in
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: log.date)
            return String(components.yearForWeekOfYear ?? 0) + "-" + String(format: "%02d", components.weekOfYear ?? 0)
        }
    }
    var logsByMonth: Dictionary<String, [Log]> {
        Dictionary(grouping: categoryFilter.filterLogs(historicalLogs)) { (log) -> String in
            let components = calendar.dateComponents([.year, .month], from: log.date)
            return String(components.year ?? 0) + "-" + String(format: "%02d", components.month ?? 0)
        }
    }
    var thisWeek: String {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return String(components.yearForWeekOfYear ?? 0) + "-" + String(format: "%02d", components.weekOfYear ?? 0)
    }
    var prevWeek: String {
        var dateComponent = DateComponents()
        dateComponent.weekOfYear = -1
        let prevDate = calendar.date(byAdding: dateComponent, to: Date())
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: prevDate!)
        return String(components.yearForWeekOfYear ?? 0) + "-" + String(format: "%02d", components.weekOfYear ?? 0)
    }
    var thisMonth: String {
        let components = calendar.dateComponents([.year, .month], from: Date())
        return String(components.year ?? 0) + "-" + String(format: "%02d", components.month ?? 0)
    }
    var prevMonth: String {
        var dateComponent = DateComponents()
        dateComponent.month = -1
        let prevDate = calendar.date(byAdding: dateComponent, to: Date())
        let components = calendar.dateComponents([.year, .month], from: prevDate!)
        return String(components.year ?? 0) + "-" + String(format: "%02d", components.month ?? 0)
    }
    
    var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter
    }
    
    var chartMessageA: [LocalizedStringKey] {
        var messages: [LocalizedStringKey] = []
        for i in 0...9 {
            messages.append(LocalizedStringKey("chartMessageA" + String(i)))
        }
        return messages
    }
    var chartMessageB: [LocalizedStringKey] {
        var messages: [LocalizedStringKey] = []
        for i in 0...9 {
            messages.append(LocalizedStringKey("chartMessageB" + String(i)))
        }
        return messages
    }
    var chartMessageC: [LocalizedStringKey] {
        var messages: [LocalizedStringKey] = []
        for i in 0...9 {
            messages.append(LocalizedStringKey("chartMessageC" + String(i)))
        }
        return messages
    }

    func getMessage(_ todayDone: Int, _ todaytoDo: Int, _ yesterdayDone: Int, _ yesterdayToDo: Int) -> LocalizedStringKey {
        var dailyTarget = modelData.userProfile.dailyTarget
        if dailyTarget == 0 {
            dailyTarget = 5
        }
        let selectedIndex = min(Int((todayDone/dailyTarget)*5), 9)
        if yesterdayDone < dailyTarget/2 {
            return chartMessageA[selectedIndex]
        } else if yesterdayDone < dailyTarget {
            return chartMessageB[selectedIndex]
        } else {
            return chartMessageC[selectedIndex]
        }
    }
    
    func getGreeting() -> LocalizedStringKey {
        let hour = calendar.component(.hour, from: Date())
        let name = modelData.userProfile.username
        var greeting = LocalizedStringKey("")
        if hour < 4 {
            greeting = LocalizedStringKey("Good night, \(name).")
        } else if hour < 11 {
            greeting = LocalizedStringKey("Good morning, \(name).")
        } else if hour < 14 {
            greeting = LocalizedStringKey("Hi, \(name).")
        } else if hour < 16 {
            greeting = LocalizedStringKey("Good afternoon, \(name).")
        } else if hour < 20 {
            greeting = LocalizedStringKey("Good evening, \(name).")
        } else if hour <= 24 {
            greeting = LocalizedStringKey("Good night, \(name).")
        } else {
            greeting = LocalizedStringKey("Hi, \(name).")
        }
        return greeting
    }
            
    var body: some View {
//        let logsTodayToDo = logsForCurrent[todayToDo] ?? []
//        let logsTodayDone = logsForCurrent[todayDone] ?? []
//        let logsYesterdayToDo = logsForCurrent[yesterdayToDo] ?? []
//        let logsYesterdayDone = logsForCurrent[yesterdayDone] ?? []
        
        NavigationView {
            ScrollView {
                VStack {
                    if categoryFilter.isFiltered {
                        HStack {
                            Text("Applied Fileter: \(categoryFilter.category.icon ?? "")\(categoryFilter.category.name)")
                            if categoryFilter.subCategory.name != "" {
                                Divider()
                                Text("\(categoryFilter.subCategory.icon ?? "")\(categoryFilter.subCategory.name)")
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 0)
                    }
                    HStack {
                        Spacer()
                        Text(modelData.userProfile.usericon)
                            .font(.system(size: 100))
                            .padding(.top, 20)
                        ChatBubble(direction: .left) {
                            VStack(alignment: .leading) {
                                Text(getGreeting())
                                    .padding(.bottom, 1)
                                Text(getMessage(logsTodayDone.count, logsTodayToDo.count, logsYesterdayDone.count, logsYesterdayToDo.count))
                            }
                                .padding(.all, 15)
                                .foregroundColor(Color.white)
                                .background(Color.blue)
                        }
                        Spacer()
                    }
                    .padding(.top, 3)
                    HStack {
                        Spacer()
                        VStack {
                            Text("Today")
                                .font(.headline)
                            HStack {
                                Spacer()
                                CircleCount(title: "Done", count: logsTodayDone.count, width: 80,  color: .accentColor)
                                Spacer()
                                CircleCount(title: "To Do", count: logsTodayToDo.count, width: 80,  color: .gray)
                                Spacer()
                            }
                        }
                        //Spacer()
                        VStack {
                            Text("Yesterday")
                                .font(.headline)
                            HStack {
                                Spacer()
                                CircleCount(title: "Done", count: logsYesterdayDone.count, width: 80,  color: .green)
                                Spacer()
                                CircleCount(title: "To Do", count: logsYesterdayToDo.count, width: 80,  color: .gray)
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    Divider()
                        .padding(.top, 20)
                    VStack {
                        HStack {
                            Spacer()
                            Text("Weekly Achievement")
                                .font(.title)
                            Button(action: {
                                withAnimation {
                                    self.showWeeklyDetail.toggle()
                                }
                            }) {
                                Image(systemName: "chevron.right.circle")
                                    .imageScale(.large)
                                    .rotationEffect(.degrees(showWeeklyDetail ? 90 : 0))
                                    .scaleEffect(showWeeklyDetail ? 1.5 : 1)
                                    .padding()
                            }
                            Spacer()
                        }
                        if showWeeklyDetail {
                            VStack {
                                HStack {
                                    Spacer()
                                    CircleCount(title: "This week", count: logsByWeek[thisWeek]?.count ?? 0, width: 140, color: .accentColor)
                                        .padding(20)
                                    Spacer()
                                    CircleCount(title: "Last week", count: logsByWeek[prevWeek]?.count ?? 0, width: 140, color: .green)
                                        .padding(20)
                                    Spacer()
                                }
                                WeeklyChart(prevWeekLogs: logsByWeek[prevWeek] ?? [], thisWeekLogs: logsByWeek[thisWeek] ?? [])
                                    .padding(.horizontal, 20)
                            }
                            .transition(.moveAndFade)
                            .padding(.bottom, 10)
                        }
                    }
                    Divider()
                    VStack {
                        HStack {
                            Spacer()
                            Text("Monthly Achievement")
                                .font(.title)
                            Button(action: {
                                withAnimation {
                                    self.showMonthlyDetail.toggle()
                                }
                            }) {
                                Image(systemName: "chevron.right.circle")
                                    .imageScale(.large)
                                    .rotationEffect(.degrees(showMonthlyDetail ? 90 : 0))
                                    .scaleEffect(showMonthlyDetail ? 1.5 : 1)
                                    .padding()
                            }
                            Spacer()
                        }
                        if showMonthlyDetail {
                            VStack {
                                HStack {
                                    Spacer()
                                    CircleCount(title: "This month (\(monthAbbrFromInt(Int(thisMonth.suffix(2)) ?? 1)))", count: logsByMonth[thisMonth]?.count ?? 0, width: 140,  color: .accentColor)
                                        .padding(20)
                                    Spacer()
                                    CircleCount(title: "Last month (\(monthAbbrFromInt(Int(prevMonth.suffix(2)) ?? 1)))", count: logsByMonth[prevMonth]?.count ?? 0, width: 140, color: .green)
                                        .padding(20)
                                    Spacer()
                                }
                                MonthlyChart(prevMonthLogs: logsByMonth[prevMonth] ?? [], thisMonthLogs: logsByMonth[thisMonth] ?? [])
                                    .padding(.horizontal, 20)
                            }
                            .transition(.moveAndFade)
                        }
                    }
                    .padding(.bottom, 20)

//                    if logsByMonth[thisMonth] != nil {
//                        if groupByCategory(logsByMonth[thisMonth]!)["Book"] != nil {
//                            Text("Book: \(groupByCategory(logsByMonth[thisMonth]!)["Book"]!.count)")
//                        }
//                    }

                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarTitle("Status")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            activeSheet = .profile
                        }) {
                            Image(systemName: "person.crop.circle")
                                .accessibilityLabel("User Profile")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            activeSheet = .settings
                        }) {
                            if categoryFilter.isFiltered == false {
                                Image(systemName: "line.horizontal.3.decrease.circle")
                            } else {
                                Image(systemName: "line.horizontal.3.decrease.circle.fill")
                            }
                        }
                    }
                }
                .sheet(item: $activeSheet) {item in
                    switch item {
                    case .settings:
                        CategoryFilterSheet()
                    
                    case .profile:
                        ProfileHost()
                            .environmentObject(modelData)
                    }
                }

            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    func groupByCategory(_ logs : [Log])-> Dictionary<String, [Log]> {
        return  Dictionary(grouping: logs) { (log) -> String in
            log.category ?? ""
        }
    }
    func monthAbbrFromInt(_ month: Int) -> String {
        let mon = calendar.shortMonthSymbols
        return mon[month - 1]
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView()
            .environmentObject(ModelData())
    }
}
