# flutter-cljd

![Alpha Status](https://img.shields.io/badge/status-alpha-red)

ClojureDart wrapper for Flutter Material widgets, designed to simplify and compact Flutter development in ClojureDart. It provides concise, Clojure-like syntax to work with Flutter’s Material components and types, making code more readable and expressive for Clojure developers building Flutter apps.

## Main Goals

### Provide a more concise and readable UI syntax
The library focuses on simplifying the syntax for building Flutter UIs, making it more compact, intuitive, and aligned with Clojure’s functional style.

```clojure
;; Basic button with styling
(->> (text "Click me!")
     (with-style {:color :blue, :size 16})
     (padding {:h 16 :v 8})
     (button #(println "Clicked!")))
```
```clojure
;; Card with multiple elements
(->> (row {:spacing 10}
       (text "Title" {:size 20 :weight :bold})
       (text "Subtitle" {:color :gray}))
     (padding {:all 16})
     (card {:elevation 2 :radius 8}))
```
```clojure
;; Simple UI components with functional composition
(ns readme.example
  (:require [flutter-cljd.widgets :as ui]))

;; Complete example: User profile card
(defn profile-card [{:keys [name role avatar]}]
  (->> (ui/row
         ;; Avatar section
         (->> avatar
              (ui/circle {:size 40})
              (ui/padding {:right 12}))
         
         ;; Text content
         (ui/column {:spacing 10}
           (ui/text name {:size 18 :weight :bold})
           (ui/text role {:size 14})))
       (ui/with-style {:color :gray})
       (ui/padding {:all 16})
       (ui/card {:elevation 4 :radius 12})
       (ui/center)))

;; Usage example
(def user-profile
  (profile-card
    {:name "John Doe"
     :role "Senior Developer"
     :avatar (image "path/to/avatar.png")}))
```

### Use Clojure data structures for better consistency and flexibility
The API is designed around pure Clojure types instead of Dart’s, offering a more seamless and consistent experience for Clojure developers while increasing code flexibility.

### Streamline and enhance Dart APIs
The library simplifies certain Dart APIs, making them easier to use and more expressive, improving the overall developer experience.
