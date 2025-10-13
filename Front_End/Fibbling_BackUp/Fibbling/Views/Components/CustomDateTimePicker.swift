//
//  CustomDateTimePicker.swift
//  Fibbling
//
//  Custom date/time pickers that look consistent across all devices
//

import SwiftUI

// MARK: - Custom Date Picker

struct CustomDatePicker: View {
    @Binding var selectedDate: Date
    let title: String
    let icon: String
    @State private var showPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.textPrimary)
            
            Button(action: {
                showPicker.toggle()
            }) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.brandPrimary)
                    
                    Text(selectedDate.relativeFormatted)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .rotationEffect(.degrees(showPicker ? 180 : 0))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.bgCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(showPicker ? Color.brandPrimary : Color.gray.opacity(0.2), lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if showPicker {
                VStack(spacing: 0) {
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                    .background(Color.bgCard)
                    
                    HStack {
                        Button("Cancel") {
                            showPicker = false
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        
                        Divider()
                            .frame(height: 40)
                        
                        Button("Done") {
                            showPicker = false
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .background(Color.bgSurface)
                }
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brandPrimary, lineWidth: 1)
                )
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showPicker)
    }
}

// MARK: - Custom Time Range Picker

struct CustomTimeRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isFullDay: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Full Day Toggle
            Toggle(isOn: $isFullDay.animation()) {
                HStack(spacing: 8) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.brandAccent)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Full Day Event")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text("Event lasts all day")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .tint(.brandPrimary)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFullDay ? Color.brandPrimary : Color.clear, lineWidth: 2)
                    )
            )
            .onChange(of: isFullDay) { _, newValue in
                if newValue {
                    // Set to full day (midnight to midnight next day)
                    startDate = startDate.startOfDay
                    endDate = startDate.endOfDay
                }
            }
            
            if !isFullDay {
                // Time Pickers
                HStack(spacing: 12) {
                    CustomTimePicker(
                        selectedDate: $startDate,
                        title: "Start Time",
                        icon: "clock.fill"
                    )
                    
                    CustomTimePicker(
                        selectedDate: $endDate,
                        title: "End Time",
                        icon: "clock.badge.checkmark.fill"
                    )
                }
                
                // Duration Display
                HStack {
                    Image(systemName: "hourglass")
                        .font(.system(size: 14))
                        .foregroundColor(.brandAccent)
                    
                    Text("Duration: \(DurationFormatter.formatDetailed(from: startDate, to: endDate))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            } else {
                // Full Day Duration Display
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14))
                        .foregroundColor(.brandAccent)
                    
                    Text(startDate.isMultiDay(endDate: endDate) ? 
                         "\(startDate.duration(to: endDate).days + 1) Days" : 
                         "Full Day Event")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Custom Time Picker (Hours & Minutes)

struct CustomTimePicker: View {
    @Binding var selectedDate: Date
    let title: String
    let icon: String
    @State private var showPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.textSecondary)
            
            Button(action: {
                showPicker.toggle()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.brandPrimary)
                    
                    Text(selectedDate.formattedForDisplay(style: .none, timeStyle: .short))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.textSecondary)
                        .rotationEffect(.degrees(showPicker ? 180 : 0))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.bgCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(showPicker ? Color.brandPrimary : Color.gray.opacity(0.2), lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showPicker) {
                TimePickerSheet(selectedDate: $selectedDate, showPicker: $showPicker)
                    .presentationDetents([.height(400)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var showPicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    showPicker = false
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textSecondary)
                
                Spacer()
                
                Text("Select Time")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("Done") {
                    showPicker = false
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.brandPrimary)
            }
            .padding()
            .background(Color.bgSurface)
            
            Divider()
            
            // Time Picker
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
        }
        .background(Color.bgSurface)
    }
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    let isEnabled: Bool
    
    init(color: Color = .brandPrimary, isEnabled: Bool = true) {
        self.color = color
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: isEnabled ? 
                                [color, color.opacity(0.8)] : 
                                [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isEnabled ? color.opacity(0.3) : Color.clear,
                        radius: configuration.isPressed ? 4 : 8,
                        x: 0,
                        y: configuration.isPressed ? 2 : 4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? (configuration.isPressed ? 0.9 : 1.0) : 0.6)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let color: Color
    let isEnabled: Bool
    
    init(color: Color = .brandPrimary, isEnabled: Bool = true) {
        self.color = color
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(isEnabled ? color : .textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isEnabled ? color : Color.gray.opacity(0.3), lineWidth: 1.5)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 0.5)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

