//
//  Tooltip.swift
//
//  Created by Antoni Silvestrovic on 19/10/2020.
//  Copyright © 2020 Quassum Manus. All rights reserved.
//

import SwiftUI

struct TooltipModifier<TooltipContent: View>: ViewModifier {
    // MARK: - Uninitialised properties
    var enabled: Bool
    var config: TooltipConfig
    var content: TooltipContent


    // MARK: - Initialisers

    init(enabled: Bool, config: TooltipConfig, @ViewBuilder content: @escaping () -> TooltipContent) {
        self.enabled = enabled
        self.config = config
        self.content = content()
    }

    // MARK: - Local state

    @State private var contentWidth: CGFloat = 10
    @State private var contentHeight: CGFloat = 10
    
    @State var animationOffset: CGFloat = 0
    @State var animation: Optional<Animation> = nil

    // MARK: - Computed properties

    var showArrow: Bool { config.showArrow && config.side.shouldShowArrow() }
    var actualArrowHeight: CGFloat { self.showArrow ? config.arrowHeight : 0 }

    var arrowOffsetX: CGFloat {
        switch config.side {
        case .bottom, .center, .top:
            return 0
        case .left:
            return (contentWidth / 2 + config.arrowHeight / 2)
        case .topLeft, .bottomLeft:
            return (contentWidth / 2
                + config.arrowHeight / 2
                - config.borderRadius / 2
                - config.borderWidth / 2)
        case .right:
            return -(contentWidth / 2 + config.arrowHeight / 2)
        case .topRight, .bottomRight:
            return -(contentWidth / 2
                + config.arrowHeight / 2
                - config.borderRadius / 2
                - config.borderWidth / 2)
        }
    }

    var arrowOffsetY: CGFloat {
        switch config.side {
        case .left, .center, .right:
            return 0
        case .top:
            return (contentHeight / 2 + config.arrowHeight / 2)
        case .topRight, .topLeft:
            return (contentHeight / 2
                + config.arrowHeight / 2
                - config.borderRadius / 2
                - config.borderWidth / 2)
        case .bottom:
            return -(contentHeight / 2 + config.arrowHeight / 2)
        case .bottomLeft, .bottomRight:
            return -(contentHeight / 2
                + config.arrowHeight / 2
                - config.borderRadius / 2
                - config.borderWidth / 2)
        }
    }

    // MARK: - Helper functions

    private func offsetHorizontal(_ g: GeometryProxy) -> CGFloat {
        switch config.side {
        case .left, .topLeft, .bottomLeft:
            return -(contentWidth + config.margin + actualArrowHeight + animationOffset)
        case .right, .topRight, .bottomRight:
            return g.size.width + config.margin + actualArrowHeight + animationOffset
        case .top, .center, .bottom:
            let offsetX = (g.size.width - contentWidth) / 2
            let overflowWidth = UIScreen.main.bounds.width - (g.frame(in: .global).origin.x + offsetX + contentWidth)
            if overflowWidth < 0 {
                return offsetX + overflowWidth - config.margin
            }
            let hStartCoordinate = g.frame(in: .global).origin.x + offsetX
            if hStartCoordinate < 0 {
                return offsetX - hStartCoordinate + config.margin
            }
            return offsetX
        }
    }

    private func offsetVertical(_ g: GeometryProxy) -> CGFloat {
        switch config.side {
        case .top, .topRight, .topLeft:
            return -(contentHeight + config.margin + actualArrowHeight + animationOffset)
        case .bottom, .bottomLeft, .bottomRight:
            return g.size.height + config.margin + actualArrowHeight + animationOffset
        case .left, .center, .right:
            let offsetY = (g.size.height - contentHeight) / 2
            let overflowHeight = UIScreen.main.bounds.height - (g.frame(in: .global).origin.y + offsetY + contentHeight)
            if overflowHeight < 0 {
                return offsetY + overflowHeight - config.margin - g.safeAreaInsets.bottom
            }
            let vStartCoordinate = g.frame(in: .global).origin.y + offsetY
            if vStartCoordinate < 0 {
                return offsetY - vStartCoordinate + config.margin + g.safeAreaInsets.top
            }
            return offsetY
        }
    }
    
    private func offsetArrowHorizontal(_ g: GeometryProxy) -> CGFloat {
        switch config.side {
        case .top, .bottom:
            let offsetX = (g.size.width - contentWidth) / 2
            let overflowWidth = UIScreen.main.bounds.width - (g.frame(in: .global).origin.x + offsetX + contentWidth)
            if overflowWidth < 0 {
                return -(overflowWidth - config.margin) - (g.size.width / 4)
            }
            let hStartCoordinate = g.frame(in: .global).origin.x + offsetX
            if hStartCoordinate < 0 {
                return hStartCoordinate - config.margin + (g.size.width / 4)
            }
            return 0
        default:
            return 0
        }
    }
    
    private func offsetArrowVertical(_ g: GeometryProxy) -> CGFloat {
        switch config.side {
        case .left, .right:
            let offsetY = (g.size.height - contentHeight) / 2
            let overflowHeight = UIScreen.main.bounds.height - (g.frame(in: .global).origin.y + offsetY + contentHeight)
            if overflowHeight < 0 {
                return config.margin - overflowHeight
            }
            let vStartCoordinate = g.frame(in: .global).origin.y + offsetY
            if vStartCoordinate < 0 {
                return vStartCoordinate - config.margin
            }
            return 0
        default:
            return 0
        }
    }
    
    // MARK: - Animation stuff
    
    private func dispatchAnimation() {
        if (config.enableAnimation) {
            DispatchQueue.main.asyncAfter(deadline: .now() + config.animationTime) {
                self.animationOffset = config.animationOffset
                self.animation = config.animation
                DispatchQueue.main.asyncAfter(deadline: .now() + config.animationTime*0.1) {
                    self.animationOffset = 0
                    
                    self.dispatchAnimation()
                }
            }
        }
    }

    // MARK: - TooltipModifier Body Properties

    private var sizeMeasurer: some View {
        GeometryReader { g in
            Text("")
                .onAppear {
                    self.contentWidth = config.width ?? g.size.width
                    self.contentHeight = config.height ?? g.size.height
                }
        }
    }

    private func getArrowView(overflowOffset: CGPoint) -> some View {
        guard let arrowAngle = config.side.getArrowAngleRadians() else {
            return AnyView(EmptyView())
        }
        
        return AnyView(ArrowShape()
            .rotation(Angle(radians: arrowAngle))
            .stroke(config.borderColor)
            .background(ArrowShape()
                .offset(x: 0, y: 1)
                .rotation(Angle(radians: arrowAngle))
                .frame(width: config.arrowWidth+2, height: config.arrowHeight+1)
                .foregroundColor(config.backgroundColor)
                
            ).frame(width: config.arrowWidth, height: config.arrowHeight)
            .offset(x: self.arrowOffsetX + overflowOffset.x, y: self.arrowOffsetY + overflowOffset.y))
    }

    private func getArrowCutoutMask(overflowOffset: CGPoint) -> some View {
        guard let arrowAngle = config.side.getArrowAngleRadians() else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            ZStack {
                Rectangle()
                    .frame(
                        width: self.contentWidth + config.borderWidth * 2,
                        height: self.contentHeight + config.borderWidth * 2)
                    .foregroundColor(.white)
                Rectangle()
                    .frame(
                        width: config.arrowWidth,
                        height: config.arrowHeight + config.borderWidth)
                    .rotationEffect(Angle(radians: arrowAngle))
                    .offset(
                        x: self.arrowOffsetX + overflowOffset.x,
                        y: self.arrowOffsetY + overflowOffset.y)
                    .foregroundColor(.black)
            }
            .compositingGroup()
            .luminanceToAlpha()
        )
    }

    var tooltipBody: some View {
        GeometryReader { g in
            let offsetX = self.offsetHorizontal(g)
            let offsetY = self.offsetVertical(g)
            let arrowOffsetX = self.offsetArrowHorizontal(g)
            let arrowOffsetY = self.offsetArrowVertical(g)
            
            let arrowView = getArrowView(overflowOffset: CGPoint(x: arrowOffsetX, y: arrowOffsetY))
            let arrowCutoutMask = getArrowCutoutMask(overflowOffset: CGPoint(x: arrowOffsetX, y: arrowOffsetY))
            ZStack {
                RoundedRectangle(cornerRadius: config.borderRadius)
                    .stroke(config.borderWidth == 0 ? Color.clear : config.borderColor)
                    .frame(width: contentWidth, height: contentHeight)
                    .background(
                        RoundedRectangle(cornerRadius: config.borderRadius)
                            .foregroundColor(config.backgroundColor)
                    )
                    .mask(arrowCutoutMask)
                
                ZStack {
                    content
                        .padding(config.contentPaddingEdgeInsets)
                        .frame(
                            width: config.width,
                            height: config.height
                        )
                        .fixedSize(horizontal: config.width == nil, vertical: true)
                }
                .background(self.sizeMeasurer)
                .overlay(arrowView)
            }
            .offset(x: offsetX, y: offsetY)
            .animation(self.animation)
            .zIndex(config.zIndex)
            .onAppear {
                self.dispatchAnimation()
            }
        }
    }

    // MARK: - ViewModifier properties

    func body(content: Content) -> some View {
        content
            .overlay(enabled ? tooltipBody.transition(config.transition) : nil)
    }
}

struct Tooltip_Previews: PreviewProvider {
    static var previews: some View {
        var config = DefaultTooltipConfig(side: .top)
        config.enableAnimation = false
//        config.backgroundColor = Color(red: 0.8, green: 0.9, blue: 1)
//        config.animationOffset = 10
//        config.animationTime = 1
//        config.width = 120
//        config.height = 80
        
        
        return VStack {
            Text("Say...").tooltip(config: config) {
                Text("Something nice!")
            }
        }.previewDevice(.init(stringLiteral: "iPhone 12 mini"))
    }
}
