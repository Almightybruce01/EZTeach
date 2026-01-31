//
//  ReportCardService.swift
//  EZTeach
//
//  PDF Report Card Generation
//

import Foundation
import UIKit
import PDFKit

class ReportCardService {
    static let shared = ReportCardService()
    
    // MARK: - Generate PDF Report Card
    func generateReportCard(
        student: Student,
        schoolName: String,
        classGrades: [ClassGradeInfo],
        semester: String,
        overallGPA: Double
    ) -> Data? {
        
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        
        let pdfMetaData = [
            kCGPDFContextCreator: "EZTeach",
            kCGPDFContextAuthor: schoolName,
            kCGPDFContextTitle: "Report Card - \(student.fullName)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = margin
            
            // Header
            yPosition = drawHeader(
                schoolName: schoolName,
                semester: semester,
                yPosition: yPosition,
                pageWidth: pageWidth,
                margin: margin
            )
            
            // Student info
            yPosition = drawStudentInfo(
                student: student,
                yPosition: yPosition,
                pageWidth: pageWidth,
                margin: margin
            )
            
            // Grades table
            yPosition = drawGradesTable(
                classGrades: classGrades,
                yPosition: yPosition,
                pageWidth: pageWidth,
                margin: margin
            )
            
            // Overall GPA
            yPosition = drawOverallGPA(
                gpa: overallGPA,
                yPosition: yPosition,
                pageWidth: pageWidth,
                margin: margin
            )
            
            // Footer
            drawFooter(
                pageRect: pageRect,
                margin: margin
            )
        }
        
        return data
    }
    
    // MARK: - Drawing Helpers
    private func drawHeader(schoolName: String, semester: String, yPosition: CGFloat, pageWidth: CGFloat, margin: CGFloat) -> CGFloat {
        var y = yPosition
        
        // School name
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor(red: 10/255, green: 31/255, blue: 68/255, alpha: 1)
        ]
        
        let titleRect = CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: 30)
        schoolName.draw(in: titleRect, withAttributes: titleAttributes)
        y += 35
        
        // Report Card title
        let subtitleFont = UIFont.systemFont(ofSize: 18)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        let subtitleRect = CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: 25)
        "OFFICIAL REPORT CARD".draw(in: subtitleRect, withAttributes: subtitleAttributes)
        y += 25
        
        // Semester
        let semesterFont = UIFont.systemFont(ofSize: 14)
        let semesterAttributes: [NSAttributedString.Key: Any] = [
            .font: semesterFont,
            .foregroundColor: UIColor.gray
        ]
        
        let semesterRect = CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: 20)
        semester.draw(in: semesterRect, withAttributes: semesterAttributes)
        y += 30
        
        // Divider line
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        UIColor(red: 10/255, green: 31/255, blue: 68/255, alpha: 1).setStroke()
        path.lineWidth = 2
        path.stroke()
        y += 20
        
        return y
    }
    
    private func drawStudentInfo(student: Student, yPosition: CGFloat, pageWidth: CGFloat, margin: CGFloat) -> CGFloat {
        var y = yPosition
        
        let labelFont = UIFont.systemFont(ofSize: 12)
        let valueFont = UIFont.boldSystemFont(ofSize: 14)
        
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: UIColor.gray
        ]
        
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: UIColor.black
        ]
        
        // Student name
        "Student Name:".draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        student.fullName.draw(at: CGPoint(x: margin + 100, y: y), withAttributes: valueAttributes)
        
        // Student ID
        "Student ID:".draw(at: CGPoint(x: pageWidth/2, y: y), withAttributes: labelAttributes)
        student.studentCode.draw(at: CGPoint(x: pageWidth/2 + 80, y: y), withAttributes: valueAttributes)
        y += 25
        
        // Grade level
        "Grade Level:".draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        "Grade \(student.gradeLevel)".draw(at: CGPoint(x: margin + 100, y: y), withAttributes: valueAttributes)
        
        y += 40
        
        return y
    }
    
    private func drawGradesTable(classGrades: [ClassGradeInfo], yPosition: CGFloat, pageWidth: CGFloat, margin: CGFloat) -> CGFloat {
        var y = yPosition
        let tableWidth = pageWidth - 2 * margin
        
        // Table header
        let headerFont = UIFont.boldSystemFont(ofSize: 12)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        // Header background
        let headerRect = CGRect(x: margin, y: y, width: tableWidth, height: 25)
        UIColor(red: 10/255, green: 31/255, blue: 68/255, alpha: 1).setFill()
        UIBezierPath(rect: headerRect).fill()
        
        // Header text
        "CLASS".draw(at: CGPoint(x: margin + 10, y: y + 6), withAttributes: headerAttributes)
        "TEACHER".draw(at: CGPoint(x: margin + 200, y: y + 6), withAttributes: headerAttributes)
        "PERCENT".draw(at: CGPoint(x: margin + 350, y: y + 6), withAttributes: headerAttributes)
        "GRADE".draw(at: CGPoint(x: margin + 430, y: y + 6), withAttributes: headerAttributes)
        y += 25
        
        // Table rows
        let rowFont = UIFont.systemFont(ofSize: 11)
        let gradeFont = UIFont.boldSystemFont(ofSize: 12)
        
        for (index, grade) in classGrades.enumerated() {
            let isEven = index % 2 == 0
            let rowRect = CGRect(x: margin, y: y, width: tableWidth, height: 22)
            
            if isEven {
                UIColor(white: 0.95, alpha: 1).setFill()
                UIBezierPath(rect: rowRect).fill()
            }
            
            let rowAttributes: [NSAttributedString.Key: Any] = [
                .font: rowFont,
                .foregroundColor: UIColor.black
            ]
            
            let gradeAttributes: [NSAttributedString.Key: Any] = [
                .font: gradeFont,
                .foregroundColor: gradeColor(grade.gradePercent)
            ]
            
            grade.className.draw(at: CGPoint(x: margin + 10, y: y + 5), withAttributes: rowAttributes)
            grade.teacherName.draw(at: CGPoint(x: margin + 200, y: y + 5), withAttributes: rowAttributes)
            String(format: "%.1f%%", grade.gradePercent).draw(at: CGPoint(x: margin + 350, y: y + 5), withAttributes: rowAttributes)
            letterGrade(grade.gradePercent).draw(at: CGPoint(x: margin + 440, y: y + 5), withAttributes: gradeAttributes)
            
            y += 22
        }
        
        // Table border
        let tableRect = CGRect(x: margin, y: yPosition, width: tableWidth, height: y - yPosition)
        UIColor.lightGray.setStroke()
        UIBezierPath(rect: tableRect).stroke()
        
        y += 20
        
        return y
    }
    
    private func drawOverallGPA(gpa: Double, yPosition: CGFloat, pageWidth: CGFloat, margin: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Background box
        let boxWidth: CGFloat = 200
        let boxRect = CGRect(x: pageWidth - margin - boxWidth, y: y, width: boxWidth, height: 60)
        UIColor(red: 10/255, green: 31/255, blue: 68/255, alpha: 0.1).setFill()
        UIBezierPath(roundedRect: boxRect, cornerRadius: 8).fill()
        
        // Label
        let labelFont = UIFont.systemFont(ofSize: 12)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: UIColor.darkGray
        ]
        "OVERALL AVERAGE".draw(at: CGPoint(x: pageWidth - margin - boxWidth + 20, y: y + 10), withAttributes: labelAttributes)
        
        // Value
        let valueFont = UIFont.boldSystemFont(ofSize: 24)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: gradeColor(gpa)
        ]
        let gradeText = String(format: "%.1f%% (%@)", gpa, letterGrade(gpa))
        gradeText.draw(at: CGPoint(x: pageWidth - margin - boxWidth + 20, y: y + 28), withAttributes: valueAttributes)
        
        y += 80
        
        return y
    }
    
    private func drawFooter(pageRect: CGRect, margin: CGFloat) {
        let footerFont = UIFont.systemFont(ofSize: 10)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = "Generated on \(dateFormatter.string(from: Date()))"
        
        dateString.draw(at: CGPoint(x: margin, y: pageRect.height - margin), withAttributes: footerAttributes)
        
        let disclaimer = "This is an official document generated by EZTeach."
        let disclaimerSize = disclaimer.size(withAttributes: footerAttributes)
        disclaimer.draw(at: CGPoint(x: pageRect.width - margin - disclaimerSize.width, y: pageRect.height - margin), withAttributes: footerAttributes)
    }
    
    // MARK: - Helpers
    private func letterGrade(_ percent: Double) -> String {
        switch percent {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }
    
    private func gradeColor(_ percent: Double) -> UIColor {
        switch percent {
        case 90...100: return UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1)
        case 80..<90: return UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 1)
        case 70..<80: return UIColor(red: 234/255, green: 179/255, blue: 8/255, alpha: 1)
        case 60..<70: return UIColor(red: 249/255, green: 115/255, blue: 22/255, alpha: 1)
        default: return UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1)
        }
    }
}
