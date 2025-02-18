# flutter-cljd/animations

A powerful animation system for Flutter that combines declarative motion descriptions with flexible widget animations.

## Main Goals

### 1. Rich Animation Primitives
The library provides a comprehensive set of animation primitives (motions) that go beyond Flutter's built-in `Tween` and `TweenSequence`.

### 2. Complex Value Animation
Full support for animating complex data structures like maps and vectors

### 3. Declarative API
A clean, functional approach to animation definition:
```clojure
(seq ; sequential
  (from {:scale 0.8 :opacity 0.0}
    (par {:duration 300} ; parallel
      :scale (to 1.0 :curve :spring)
      :opacity (to 1.0 :curve :ease-in)))
  (wait 200)
  (action! :feedback HapticFeedback.mediumImpact))
```

### 4. Integration Features
Seamless integration with Flutter ecosystem:
- `Animation` implements `ILookup` for creating child animations with native Clojure functions like `get`, `get-in`, etc.
- `map-anim` for custom animation transformations
- Compatible with Flutter's animation widgets
- Built-in curve library via `flutter-cljd/curves`

### 5. `animated` widget
`animated` widget provides elegant way to animate any widget based on input changes, eliminating the need of special implicity animated widgets like `AnimatedPadding`, `AnimatedSize`, `AnimatedOpacity`, etc.

Also it can be driven with an `Animation` instance and used as `AnimatedBuilder` widget.

## Showcase Examples

### Hero Card Animation
```clojure
(widget
  :managed [controller (motion-controller
                        vsync 
                        (from
                          ;; Start collapsed
                          {:scale 0.8
                           :opacity 0.0
                           :offset-y 50.0
                           :rotation 0.0}
                          ;; Expand with spring effect
                          (parallel {:duration 800}
                            :scale (to 1.0 1.05 1.0 :curve :spring)
                            :opacity (to 1.0 :relative-duration 0.5)
                            :offset-y (to 0.0 :curve :ease-out)
                            ;; Subtle rotation for style
                            :rotation (to -2.0 2.0 0.0 :curve :ease-in-out))))]
  (->> (card)
       (animated (:scale controller) scale)
       (animated (:opacity controller) opacity)
       (animated (:offset-y controller) offset :dy)
       (animated (:rotation controller) rotate)
       (on-appear #(.forward controller))))
```

### Interactive Loading Animation
```clojure
(widget
  :managed [controller (motion-controller 
                        vsync
                        (seq
                          :duration 2000
                          ;; Initial value
                          (to {:dots [0 0 0] :scale 1 :rotation 0})
                          ;; Dots appear one by one
                          (par :dots
                               (par (map #(to 1 :curve :ease-out :delay (* % 100)) (range 3))))
                          ;; Dots pulse and rotate together
                          (par
                            ;; Scale pulses
                            :scale (tile (to 1.2 1.0 
                                          :duration 600 
                                          :curve :ease-in-out))
                            ;; Continuous rotation
                            :rotation (tile (to (* 2 pi) 
                                              :duration 1500 
                                              :curve :linear)))))]
  (stack
    (for [i (range 3)]
      (->> (circle :radius 8 :color Colors.blue)
           (animated (get-in controller [:dots i]) opacity)
           (animated (:scale controller) scale)
           (animated (:rotation controller) rotate)))))
```

### Menu Transition
```clojure
(widget
  :managed [controller (motion-controller 
                        vsync
                        (par
                          ;; Background  dim
                          :overlay (to 1.0 0.5 :curve :ease-in)
                          ;; Menu slides in with items
                          :menu (seq
                                 ;; Initial value
                                 (to {:offset 0 :fade [0 0 0]})
                                 ;; Slide in from left
                                 (par :offset
                                      (to -300 0
                                         :duration 500 
                                         :curve :ease-out))
                                 ;; Items fade in sequentially
                                 (par :fade
                                      (seq
                                        (map
                                          #(par % 
                                                (to 1.0
                                                    :curve :ease-out
                                                    :duration 100))
                                          (range 3)))))))]
  (stack
    ;; Dimming overlay
    (->> (container :color Colors.black)
         (animated (:overlay controller) opacity))
    ;; Menu
    (->> (column
           (for [i (range 3)]
             (->> (menu-item)
                  (animated (get-in controller [:menu :fade i] 0) opacity))))
         (animated (get-in controller [:menu :offset] 0) offset dx))))
```

### Success Checkmark
```clojure
(widget
  :managed [controller (motion-controller
                        vsync
                        (seq
                          ;; Initial value
                          (to {:circle 0.0 :check 0.0 :scale 1.0})
                          ;; Circle expands
                          (par {:duration 400}
                            :circle (to 1.0 :curve :ease-out)
                            ;; Checkmark draws
                            :check (seq
                                    (wait 200)
                                    (to 1.0 :curve :ease-in-out)))
                          ;; Trigger feedback
                          (action! :m HapticFeedback.mediumImpact)
                          ;; Success bounce
                          (par {:duration 200}
                            :scale (to 1.2 1.0 :curve :spring))))]
  (->> (stack
         ;; Background circle
         (->> (circle :color Colors.green)
              (animated (:circle controller) scale))
         ;; Checkmark path
         (->> (custom-paint :painter (checkmark-painter))
              (animated (:check controller) 
                       #(paint-progress %1 :color Colors.white %2))))
       (animated (:scale controller) scale)))
```

## Motion System

Motions describe how values change over time. They are used by motion controllers to drive animations.
`Motion` is an `Animatable` subclass that supports intrinsic duration and composition.

### Motion Controller

Motion controllers manage the lifecycle and playback of animations. Unlike `AnimationController`, motion controllers provide an animated value rather just a progress value.

```clojure
(widget
  :managed [animation (motion-controller 
                         vsync 
                         (duration 200 (to 0 100)))]
  (->> (text "Animated")
       (animated animation opacity)))
```

### Motions

Value Changes:
- `to`, `from`, `from-to`: Smooth transitions between values
- `const`: Discrete value changes without interpolation
- `instant`: Immediate value changes
- `wait`: Pause for specified durations

Composition:
- `seq`: Sequential animations with precise timing control
- `par`: Parallel animations with synchronized timing
- `repeat`, `autoreverse`: Animation repetition patterns
- `synced`, `tile`: Time-based synchronization and tiling

Configuration:
- `with`: Unified configuration interface
- `duration`, `curve`: Basic timing and easing
- `delay`, `relative-duration`, `relative-delay`: Advanced timing control
- `action!`: Side effect triggers during animation

## `with-motion` widget
The `with-motion` widget provides dynamic motion creation and management. While using the `:managed` key in the `widget` macro can hold a `motion-controller`, it won't automatically rebuild motions when dependent values change. `with-motion` solves this by recreating motions when their definitions change:

```clojure
;; Single motion example
(widget
  :vsync vsync
  :watch [transparent? (atom false)]
  (with-motion 
    vsync
    (duration 200
      (from-to 1 (if transparent? 0 1)))
    (fn [ctx controller]
      (->> some-widget
           (animated controller opacity)))))

;; Multiple motions
(widget
  :vsync vsync
  :watch [expanded? (atom false)]
  (with-motion 
    vsync
    (from-to 0 (if expanded? 1 0))  ; opacity motion
    (from-to 0 (if expanded? 100 0)) ; offset motion 
    (fn [ctx opacity-ctrl offset-ctrl]
      (->> some-widget
           (animated opacity-ctrl opacity)
           (animated offset-ctrl offset)))))
```

The widget takes:
1. A vsync source (usually from widget's :vsync)
2. One or more motion definitions
3. A builder function that receives the context and motion controllers

Key features:
- Automatically recreates motions when their definitions change
- Manages motion controller lifecycle
- Supports multiple synchronized motions
- Provides context and controllers to the builder function

## `animated` Widget

The `animated` widget can be used in two ways to create animations in Flutter:


### 1. Implicit Animations

Implicit animations automatically animate between property changes using a tween animation. This is the simpler way to create animations:

To animate a widget property, simply wrap the modifier with `animated`:

```clojure
;; Static opacity
(->> child
  (opacity 0.5))

;; Animated opacity
(->> child
  (animated opacity (if transparent? 0.5 1)))

;; With options
(->> (text "Hello")
     (animated {:duration 300 :curve :ease-in-out} opacity opacity-value))

;; Multiple arguments
(->> (text "Sizing")
     (animated sized width height)) ;; animate when width or height changes.

(->> (text "Sizing")
     (animated (fn [{:keys [width height]} child]
                   (sized width height child))
               size-map)) ; target value animate to
```

### 2. Explicit Animations

Explicit animations give you direct control over the animation using an Animation object:

```clojure
(widget
  :vsync vsync
  :managed [controller (motion-controller vsync (from-to 0 100))]
  (->> (text "Controlled")
       (animated controller offset)))

(widget
  :vsync vsync
  :managed [controller (motion-controller 
                         vsync
                         (from-to {:offset 0 :opacity 0}
                                  {:offset 100 :opacity 1}))]
  (->> (text "Reactive")
       (animated (:offset controller) offset) ;; Animation object can be transformed with a key or `map-anim` function
       (animated (map-anim #(get :opacity %) controller) opacity)))
       
(widget
  :vsync vsync
  :managed [controller (motion-controller vsync (from-to 0 100))]
  (->> (text "Controlled")
       (animated controller offset :dx 50 :dy))) ;; controller value is appended after all arguments
```

### Efficient Child Widget Usage

Both implicit and explicit animations can accept a child widget, making them more efficient when animating large widget trees:

```clojure
;; Without child - entire widget tree is rebuilt on each frame, that's okay for small widgets but it's inefficient for large widget trees
(animated 
  {:duration 200} 
   opacity-value
  (fn [value]
      (->>
        (text "Title")
        (padding 20)
        (opacity value)))))

;; With child - only opacity modifier is rebuilt
(->>
    (column
      (text "Title")
      (text "Subtitle")
      (image "large-image.png"))
    (padding 20)
    (animated {:duration 200} opacity opacity-value))
```

