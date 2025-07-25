import UIKit

public final class PieChartView: UIView {
    public var entities: [Entity] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private let ringThicknessRatio: CGFloat = 0.2
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        guard !entities.isEmpty,
              let ctx = UIGraphicsGetCurrentContext() else { return }
        
        // 1) Считаем общую сумму и строим массив до 6 элементов
        let total = entities.map(\.value).reduce(0, +)
        guard total > 0 else { return }
        
        let topFive = Array(entities.prefix(5))
        let rest    = Array(entities.dropFirst(5))
        var drawing = topFive
        if !rest.isEmpty {
            let sumRest = rest.map(\.value).reduce(0, +)
            drawing.append(Entity(value: sumRest, label: "Остальные"))
        }
        
        // 2) Настраиваем центр, радиус и толщину кольца
        let center     = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) * 0.4
        let thickness   = outerRadius * ringThicknessRatio
        let radius      = outerRadius - thickness / 2
        
        // 3) Рисуем сегменты-дуги
        var startAngle: CGFloat = -CGFloat.pi / 2
        
        for (idx, ent) in drawing.enumerated() {
            let percent = (ent.value as NSDecimalNumber).doubleValue
            / (total   as NSDecimalNumber).doubleValue
            let sweep    = CGFloat(percent) * 2 * CGFloat.pi
            let endAngle = startAngle + sweep
            
            ctx.setLineWidth(thickness)
            ctx.setLineCap(.butt)
            ctx.setStrokeColor(
                PieChartColors.segmentColors[
                    idx % PieChartColors.segmentColors.count
                ].cgColor
            )
            
            ctx.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            ctx.strokePath()
            
            startAngle = endAngle
        }
        
        // 4) Легенда по центру кольца
        // Теперь легенда слева в центре кольца
        let legendFont = UIFont.systemFont(ofSize: 12)
        let lineHeight = legendFont.lineHeight
        let interLineSpacing: CGFloat = 4
        let dotSize: CGFloat = 8
        let dotTextSpacing: CGFloat = 6
        let horizontalPadding: CGFloat = 8  // отступы внутри блока легенды
        
        // Подготовим строки легенды с их цветами
        let legendItems: [(color: UIColor, text: String)] = drawing.enumerated().map { idx, ent in
            let pct = (ent.value as NSDecimalNumber).doubleValue
            / (total as NSDecimalNumber).doubleValue * 100
            let txt = String(format: "%.0f%% %@", pct, ent.label)
            let col = PieChartColors.segmentColors[idx % PieChartColors.segmentColors.count]
            return (col, txt)
        }
        
        // 1) Узнаём максимальную ширину текста
        let textAttributes: [NSAttributedString.Key: Any] = [.font: legendFont]
        let maxTextWidth: CGFloat = legendItems
            .map { $0.text.boundingRect(
                with: .init(width: CGFloat.greatestFiniteMagnitude, height: lineHeight),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: textAttributes,
                context: nil
            ).width }
            .max() ?? 0
        
        // 2) Ширина всего блока: dot + dotTextSpacing + текст + 2*padding
        let blockWidth = dotSize + dotTextSpacing + maxTextWidth + horizontalPadding * 2
        // 3) Высота блока: кол‑во строк * lineHeight + промежутки между ними
        let blockHeight = CGFloat(legendItems.count) * lineHeight
        + CGFloat(legendItems.count - 1) * interLineSpacing
        
        // 4) Начальные точки так, чтобы блок был центрирован в circleCenter
        let blockOriginX = center.x - blockWidth / 2
        var currentY    = center.y - blockHeight / 2
        
        // 5) Рисуем фон (если нужен, например, semi‑transparent)
        // ctx.setFillColor(UIColor.systemBackground.withAlphaComponent(0.8).cgColor)
        // let bgRect = CGRect(x: blockOriginX, y: currentY - 4, width: blockWidth, height: blockHeight + 8)
        // ctx.fill(bgRect)
        
        // 6) Рисуем каждую строку: кружок и текст
        for item in legendItems {
            // кружок
            let dotX = blockOriginX + horizontalPadding
            let dotY = currentY + (lineHeight - dotSize) / 2
            let dotRect = CGRect(x: dotX, y: dotY, width: dotSize, height: dotSize)
            ctx.setFillColor(item.color.cgColor)
            ctx.fillEllipse(in: dotRect)
            
            // текст
            let textX = dotX + dotSize + dotTextSpacing
            let textRect = CGRect(x: textX,
                                  y: currentY,
                                  width: maxTextWidth,
                                  height: lineHeight)
            (item.text as NSString).draw(in: textRect, withAttributes: textAttributes)
            
            currentY += lineHeight + interLineSpacing
        }
    }
}
