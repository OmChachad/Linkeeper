//
//  InAppBrowserView.swift
//  InAppBrowser-SwiftUI
//
//  Created by Diego Dos Santos on 08/08/24.
//

import SwiftUI

struct InAppBrowserView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @Environment(\.openURL) var openURL
    
    @ObservedObject private var viewModel = WebViewModel()
    
    
    var bookmark: Bookmark
    @State private var notes: String = ""
    @State private var isFavorited = false
    
    init(bookmark: Bookmark) {
        self.bookmark = bookmark
        self._notes = State(initialValue: bookmark.wrappedNotes)
        self._isFavorited = State(initialValue: bookmark.isFavorited)
    }
    
    @State private var showingNotesEditor = false
    @FocusState var isNotesEditorFocused
    
    var body: some View {
        CompatibleNavigationStack {
            WebViewWrapper(url: bookmark.wrappedURL, viewModel: viewModel)
                #if os(macOS)
                .frame(minWidth: 600, minHeight: 500)
                #endif
                .overlay(alignment: .top) {
                    if showingNotesEditor {
                        VStack {
                            Text("Add Notes")
                                .bold()
                            
                            TextEditor(text: $notes)
                                .placeholder("Notes", contents: notes)
                                .focused($isNotesEditorFocused)
                                .scrollContentBackground(visibility: .hidden)
                                .background(.ultraThinMaterial.opacity(isLiquidGlass ? 0.8 : 1), in: .rect(cornerRadius: 10, style: .continuous))
                                .clipShape(.rect(cornerRadius: 10, style: .continuous))
                            
                            HStack {
                                Button {
                                    isNotesEditorFocused = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        showingNotesEditor = false
                                    }
                                } label: {
                                    Text("Cancel")
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(maxWidth: .infinity)
                                #if !os(macOS)
                                .buttonBorderShape(.roundedRectangle(radius: 10))
                                #endif
                                .buttonStyle(BorderedButtonStyle())
                                
                                Button {
                                    isNotesEditorFocused = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        showingNotesEditor = false
                                        
                                        bookmark.notes = notes
                                    }
                                } label: {
                                    Text("Save")
                                        .frame(maxWidth: .infinity)
                                }
                                #if !os(macOS)
                                .buttonBorderShape(.roundedRectangle(radius: 10))
                                #endif
                                .buttonStyle(BorderedProminentButtonStyle())
                            }
                        }
                        .padding()
                        .compatibleGlassEffect(in: .rect(cornerRadius: 25, style: .continuous), glassFallBackMaterial: .thinMaterial)
                        .padding()
                        .transition(.movingParts.boing)
                        .frame(maxHeight: 250)
                    }
                }
                .compatibleSafeAreaBar(edge: .top) {
                    HStack {
                        Button("Done", systemImage: "xmark") {
                            try? moc.save()
                            dismiss()
                        }
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .padding(10)
                        .compatibleGlassEffect(.interactive, in: .circle)
                        
                        Spacer()
                        
                        VStack(spacing: 0) {
                            Text(bookmark.wrappedTitle)
                                .lineLimit(1)
                                .font(.headline)
                            Text((viewModel.webView?.url?.host ?? bookmark.wrappedHost))
                                .lineLimit(1)
                            
                            if viewModel.isLoading {
                                ProgressView(value: viewModel.loadingProgress)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(height: 1)
                                    .animation(.default, value: viewModel.loadingProgress)
                            }
                        }
                        .padding(.horizontal)
                        .clipShape(.capsule)
                        .compatibleGlassEffect(.interactive, glassFallBackMaterial: .thinMaterial)
                        
                        Spacer()
                        
                        Button("Notes", systemImage: "text.quote") {
                            showingNotesEditor = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isNotesEditorFocused = true
                            }
                        }
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .padding(10)
                        .compatibleGlassEffect(.interactive, in: .circle)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, isLiquidGlass ? 10 : 0)
                }
                .compatibleSafeAreaBar(edge: .bottom) {
                    CompatibleGlassEffectContainer {
                        HStack {
                            HStack(spacing: 25) {
                                Button {
                                    viewModel.goBack()
                                } label: {
                                    Image(systemName: "chevron.backward")
                                }
                                .disabled(!viewModel.canGoBack)
                                
                                if viewModel.canGoForward {
                                    Button {
                                        viewModel.goForward()
                                    } label: {
                                        Image(systemName: "chevron.forward")
                                    }
                                }
                            }
                            .animation(.bouncy, value: viewModel.canGoBack)
                            .animation(.bouncy, value: viewModel.canGoForward)
                            .padding(10)
                            .compatibleGlassEffect(.interactive)
                            
                            Spacer()
                            
                            HStack(spacing: 25) {
                                Button {
                                    isFavorited.toggle()
                                } label: {
                                    if isFavorited {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.pink)
                                            .transition(.movingParts.pop(.pink))
                                    } else {
                                        Image(systemName: "heart")
                                            .foregroundColor(.pink)
                                    }
                                }
                                .keyboardShortcut("F", modifiers: [.shift, .command])
                                .onChange(of: isFavorited) { _ in
                                    bookmark.isFavorited = isFavorited
                                }
                                
                                
                                ShareButton(url: bookmark.wrappedURL) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                
                                Button {
                                    let url = viewModel.webView?.url ?? bookmark.wrappedURL
                                    
                                    openURL(url)
                                } label: {
                                    Image(systemName: "safari")
                                }
                            }
                            .padding(10)
                            .compatibleGlassEffect(.interactive)
                        }
                        .font(.title2)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 10)
                    .padding(.top, isLiquidGlass ? 10 : 0)
                }
                .animation(.bouncy.speed(1.4), value: showingNotesEditor)
                .buttonStyle(.plain)
        }
    }
}
