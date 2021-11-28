//
//  MyAxisRenderers.swift
//  Rival
//
//  Created by Yannik Schroeder on 05.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

//This is a modified version from what can be found here: https://github.com/danielgindi/Charts/issues/35

import Charts

class MyYAxisRenderer: YAxisRenderer {
    enum Position {
        case top
        case upperQuarter
        case middle
        case lowerQuarter
        case bottom
    }
    
    private var ylabel: String
    private var plotTitle: String
    private var position: Position
    public var titleSize = CGSize()
    
    required init(ylabel: String, plotTitle: String, base: BarLineChartViewBase, position: Position = .top) {
        self.position = position
        self.ylabel = ylabel
        self.plotTitle = plotTitle
        super.init(viewPortHandler: base.viewPortHandler, yAxis: base.leftAxis, transformer: base.getTransformer(forAxis: .left))
    }
    
    override func renderAxisLabels(context: CGContext) {
        super.renderAxisLabels(context: context)
        renderTitle(inContext: context)
    }
    
    func renderTitle(inContext context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.systemTeal
        ]
        
        // Determine the chart ylable's y-position.
        self.titleSize = ylabel.size(withAttributes: attributes)
        let y: CGFloat
        let x: CGFloat = viewPortHandler.offsetLeft
        let bottom = viewPortHandler.chartHeight - titleSize.width - viewPortHandler.offsetBottom
        switch(self.position) {
        case .top:
            y = 0
        case .upperQuarter:
            y = bottom * 1/3
        case .middle:
            y = bottom * 1/2
        case .lowerQuarter:
            y = bottom * 2/3
        case .bottom:
            y = bottom
        }
        let point = CGPoint(x: x, y: y)
        
        // Render the ylabel.
        ChartUtils.drawText(context: context, text: ylabel, point: point, attributes: attributes, anchor: .zero, angleRadians: .pi / -2)
        
        let plotTitleSize = plotTitle.size(withAttributes: attributes)
        let plotTitlePoint = CGPoint(x: (viewPortHandler.chartWidth-plotTitleSize.width)/2+self.axis!.xOffset, y: 0)
        ChartUtils.drawText(context: context, text: plotTitle, point: plotTitlePoint, attributes: attributes, anchor: .zero, angleRadians: 0)
    }
}

class MyXAxisRenderer: XAxisRenderer {
    public var titleLabelPadding: CGFloat = 20
    public var title: String
    
    required init(title: String, base: BarLineChartViewBase) {
        self.title = title
        super.init(viewPortHandler: base.viewPortHandler, xAxis: base.xAxis, transformer: base.getTransformer(forAxis: .left))
    }
    
    override func renderAxisLabels(context: CGContext) {
        super.renderAxisLabels(context: context)
        renderTitle(inContext: context, y: titleLabelPadding)
    }
    
    func renderTitle(inContext context: CGContext, y: CGFloat) {
        guard let xAxis = self.axis as? XAxis else { return }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: xAxis.labelTextColor
        ]
        
        // Determine the chart title's position.
        let titleSize = title.size(withAttributes: attributes)
        let point = CGPoint(x: (viewPortHandler.chartWidth - titleSize.width) / 2, y: viewPortHandler.chartHeight-titleSize.height-y)
        
        // Render the chart title.
        ChartUtils.drawText(context: context, text: title, point: point, attributes: attributes, anchor: .zero, angleRadians: 0)
    }
}
