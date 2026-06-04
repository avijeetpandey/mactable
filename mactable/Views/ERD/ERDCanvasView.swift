//
//  ERDCanvasView.swift
//  mactable
//
//  SwiftUI Canvas-backed ERD workspace. Hosts each table as a draggable
//  card via ERDNodeView, draws auto-routed Bezier wires for inferred FK
//  relationships, and provides drag-to-join interaction that compiles a
//  ready-to-run JOIN statement back into the SQL editor.
//

import SwiftUI

struct ERDCanvasView: View {
    @ObservedObject var session: ConnectionSession
    @StateObject private var viewModel = ERDViewModel()
    @State private var portAnchors: [ERDPortAnchor] = []
    @State private var canvasScale: CGFloat = 1.0
    @State private var canvasOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().opacity(0.2)
            ZStack {
                background
                relationshipLayer
                pendingWireLayer
                nodesLayer
            }
            .coordinateSpace(name: "erd-canvas")
            .onPreferenceChange(ERDPortAnchorKey.self) { portAnchors = $0 }
            generatedJoinFooter
        }
        .background(.ultraThinMaterial)
        .onAppear { viewModel.loadFromSession(session) }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.connected.to.line.below")
                .foregroundStyle(AppTheme.accent)
            Text("Visual Query Builder")
                .font(AppTypography.headline(14))
            Spacer()
            Text("\(viewModel.nodes.count) tables")
                .font(AppTypography.metadata(11))
                .foregroundStyle(AppTheme.secondaryLabel)
            Button {
                viewModel.loadFromSession(session)
            } label: {
                Label("Re-layout", systemImage: "rectangle.3.group")
            }
            .buttonStyle(HoverableButtonStyle(tint: .secondary))
            .controlSize(.small)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }

    // MARK: - Background grid

    private var background: some View {
        Canvas { context, size in
            let spacing: CGFloat = 28
            var x: CGFloat = 0
            while x < size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(AppTheme.hairline.opacity(0.18)), lineWidth: 0.5)
                x += spacing
            }
            var y: CGFloat = 0
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(AppTheme.hairline.opacity(0.18)), lineWidth: 0.5)
                y += spacing
            }
        }
    }

    private var nodesLayer: some View {
        ForEach(viewModel.nodes) { node in
            ERDNodeView(
                node: node,
                isDragging: viewModel.draggingNodeID == node.id,
                onPortRelease: { col, location in
                    let target = portAnchors.first(where: { $0.frame.contains(location) })
                    let port = target.map { ERDPort(nodeID: "\($0.table)", table: $0.table, column: $0.column, point: location) }
                    let origin = ERDPort(nodeID: node.id, table: node.table, column: col.name, point: location)
                    viewModel.startJoin(from: origin)
                    viewModel.completeJoin(target: port)
                },
                onPortDrag: { location in
                    viewModel.updateJoin(to: location)
                },
                onBodyDrag: { translation in
                    viewModel.draggingNodeID = node.id
                    viewModel.dragOffsets[node.id] = translation
                },
                onBodyDragEnded: { _ in
                    viewModel.commitDrag(for: node.id)
                    viewModel.draggingNodeID = nil
                }
            )
            .position(x: (viewModel.position(of: node.id)?.x ?? node.position.x) + node.size.width / 2,
                      y: (viewModel.position(of: node.id)?.y ?? node.position.y) + 60)
        }
    }

    private var relationshipLayer: some View {
        Canvas { context, _ in
            for node in viewModel.nodes {
                for col in node.columns {
                    guard let ref = col.foreignReference,
                          let target = viewModel.nodes.first(where: { $0.table == ref.targetTable }),
                          let from = viewModel.position(of: node.id),
                          let to = viewModel.position(of: target.id) else { continue }
                    let path = bezier(from: CGPoint(x: from.x + node.size.width, y: from.y + 40),
                                      to: CGPoint(x: to.x, y: to.y + 40))
                    context.stroke(path, with: .color(AppTheme.accent.opacity(0.6)), lineWidth: 1.5)
                }
            }
        }
    }

    private var pendingWireLayer: some View {
        Canvas { context, _ in
            guard let pending = viewModel.pendingJoin else { return }
            let path = bezier(from: pending.origin.point, to: pending.currentLocation)
            context.stroke(path, with: .color(AppTheme.warning), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        }
    }

    private func bezier(from a: CGPoint, to b: CGPoint) -> Path {
        var path = Path()
        path.move(to: a)
        let dx = (b.x - a.x) * 0.5
        path.addCurve(to: b,
                      control1: CGPoint(x: a.x + dx, y: a.y),
                      control2: CGPoint(x: b.x - dx, y: b.y))
        return path
    }

    private var generatedJoinFooter: some View {
        Group {
            if !viewModel.generatedSQL.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "wand.and.rays")
                        .foregroundStyle(AppTheme.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Generated JOIN")
                            .font(AppTypography.headline(12))
                        Text(viewModel.generatedSQL)
                            .font(AppTypography.mono(11))
                            .foregroundStyle(AppTheme.secondaryLabel)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    Button("Send to Editor") {
                        NotificationCenter.default.post(name: .runSavedQuery, object: viewModel.generatedSQL)
                    }
                    .buttonStyle(HoverableButtonStyle(tint: AppTheme.accent))
                    .controlSize(.small)
                }
                .padding(12)
                .background(.regularMaterial)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.73), value: viewModel.generatedSQL.isEmpty)
    }
}
