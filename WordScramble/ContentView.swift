//
//  ContentView.swift
//  WordScramble
//
//  Created by Víctor Ávila on 03/01/24.
//

import SwiftUI

// The UI will be composed of 3 major Views:
// 1) A NavigationStack showing the word they're spelling from
// 2) A TextField showing where they can enter their answer
// 3) A List with all the answers entered previously
    // In the beginning, the words in this List won't have any validation. Afterwards, there will be a validation to check whether the word has already been inserted, a validation to check if the word can be created from the root word, and a validation to check if the word is a real word.

struct ContentView: View {
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    @State private var score = 0
    
    // Alerts Variables
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Enter your word", text: $newWord)
                        .textInputAutocapitalization(.never) // Use this for the first letter to be not automatically uppercased
                }
                // .onSubmit needs to receive a function with no parameters and that returns nothing
                // It will be called every time the user presses Return on the keyboard
                
                Section {
                    ForEach(usedWords, id: \.self) { word in
                        // VoiceOver/Accessibility notes
                        // The score of the guessed word and the word itself are treated as separated elements when reading out
                        // The best way of solving this is grouping both Views in a single element where the children are ignored by VoiceOver and there is a label for the whole group with a much more natural description
                        HStack {
                            // Use SF Symbols to show how many letters the input word has
                            Image(systemName: "\(word.count).circle")
                            Text(word)
                        }
                        .accessibilityElement() // children: .ignore is the default
                        .accessibilityLabel("\(word), \(word.count) letters")
                        
                        // Alternatively, it could have an .accessibilityLabel and an .accessibilityHint
//                        .accessibilityLabel(word)
//                        .accessibilityHint("\(word.count) letters") // Read after a short pause
                    }
                }
                
                Section {
                    Text("Score: \(score)")
                }
            }
            .navigationTitle(rootWord)
            .onSubmit(addNewWord)
            // Adding a function that will be ran when a View is shown
            .onAppear(perform: startGame)
            .alert(errorTitle, isPresented: $showingError) {
                Button("OK") { } // This line could be empty and the result would be the same
            } message: {
                Text(errorMessage)
            }
            .toolbar {
                Button("New word", action: startGame)
            }
        }
    }
    
    func addNewWord() {
        // Lowercasing (to avoid adding the same word with different casing) and trimming whitespaces
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Exiting if there is no valid char at all
        guard answer.count > 0 else { return }
        
        // Validating the answer
        guard isDifferentThanRoot(word: answer) else {
            wordError(title: "Word is the same as root word", message: "You can't just copy it and consider as answer!")
            return
        }
        
        guard isGreaterThan2(word: answer) else {
            wordError(title: "Word is too small", message: "It's not possible to create a word with less than 3 letters!")
            return
        }
        
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original!")
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "You can't spell that word from '\(rootWord)'!")
            return
        }
        
        guard isReal(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            return
        }
        
        score += determineScore(word: answer)
        
        // Inserting the word at the beginning of the Array so it will be seen
        // Does a different animation depending on the length of the Array to represent the .insert() operation
        withAnimation {
            usedWords.insert(answer, at: 0)
        }
        newWord = ""
    }
    
    // When Xcode compiles the project, it takes all files and put them inside a single folder (the Bundle). Then, it gives a name to the app and takes it to the App Store.
    // This function finds start.txt in the Bundle, loads the asset start.txt into a String, splits the String into an Array of Strings, and then pick one random word (if it fails, we will assign a default word).
    // What if we can't locate start.txt in our Bundle because it is corrupted? This is a situation we cannot recover from. We have to use Swift's fatalError() in order to instantly crash our app.
    func startGame() {
        // Remove words from previous tries
        withAnimation {
            usedWords = []
        }
        newWord = ""
        score = 0
        
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                let allWords = startWords.components(separatedBy: "\n")
                rootWord = allWords.randomElement() ?? "silkworm"
                return
            }
        }
        
        // If something at all gone wrong
        fatalError("Could not load start.txt from the bundle.")
    }
    
    // We will add 6 methods to analyse each input word
    // 1) Is the word the same as the root word?
    // 2) Is the length of the word greater than 2 letters?
    // 3) Is the word original? (Has it been used before or not?)
    // 4) Is the word possible? (Can I get this word out of the root word?)
    // 5) Is the word real? (Is it actually a real word?)
    // 6) To handle that the error messages are shown easily.
    func isDifferentThanRoot(word: String) -> Bool {
        word != rootWord
    }
    
    func isGreaterThan2(word: String) -> Bool {
        word.count > 2
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            // If we find that letter in tempWord, assign the first occurrence of letter to the variable
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        
        return true
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
    
    func determineScore(word: String) -> Int {
        rootWord.count - word.count + 1
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().preferredColorScheme(.dark)
        ContentView().preferredColorScheme(.light)
    }
}
