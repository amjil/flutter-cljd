# flutter-cljd/animations

A powerful animation system for Flutter that combines declarative motion descriptions with flexible widget animations.

## Main Goals

### 1. Rich Animation Primitives
The library provides a comprehensive set of animation primitives that go beyond Flutter's built-in `Tween` and `TweenSequence`:

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

### 2. Complex Value Animation
Full support for animating complex data structures:
- Maps: Animate multiple properties simultaneously
- Vectors: Coordinate-based animations
- Nested structures: Deep property animation
- Custom types: Extensible interpolation system

### 3. Enhanced Animation Control
Improved animation management through:
- Relative timing: Parent-child duration relationships
- Synchronized animations: Time-based coordination
- Side effects: Integrated feedback triggers
- Progress control: Fine-grained animation state management

### 4. Declarative API
A clean, functional approach to animation definition:
```clojure
(seq
  (from {:scale 0.8 :opacity 0.0}
    (par {:duration 300}
      :scale (to 1.0 :curve :spring)
      :opacity (to 1.0 :curve :ease-in)))
  (wait 200)
  (action! :feedback HapticFeedback.mediumImpact))
```

### 5. Integration Features
Seamless integration with Flutter ecosystem:
- `Animation` implements `ILookup` for property access
- `map-anim` for custom animation transformations
- Compatible with Flutter's animation widgets
- Built-in curve library via `flutter-cljd/curves`

### `animated` widget
`animated` widget provides elegant way to animate any widget based on input changes, eliminating the need of special implicity animated widgets like `AnimatedPadding`, `AnimatedSize`, `AnimatedOpacity`, etc.
Also it can be used as `AnimatedBuilder` widget.

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
                          (par {:duration 800}
                            :scale (to 1.0 1.05 1.0 :curve :spring)
                            :opacity (to 1.0 :relative-duration 0.5)
                            :offset-y (to 0.0 :curve :ease-out)
                            ;; Subtle rotation for style
                            :rotation (to -2.0 2.0 0.0 :curve :ease-in-out))))]
  (->> (card)
       (animated (:scale controller) scale)
       (animated (:opacity controller) opacity)
       (animated (:offset-y controller) offset :dx 0 :dy)
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

### Motion Primitives

- `to`: Animate to target value(s)
  ```clojure
  (to 100)  ; To single value
  (to 0 50 100)  ; Through multiple values
  (to 0 100 :duration 1000)  ; With options
  (to {:x 0 :y 0} {:x 100 :y 50})  ; Complex values
  ```

- `from-to`: Explicit start and end values
  ```clojure
  (from-to 0 100)  ; Simple transition
  (from-to 0 50 100)  ; Through points
  ```

- `const`: Discrete value changes
  ```clojure
  (const 100)  ; Fixed value
  (const 0 50 100)  ; Step through values
  ```

- `wait`: Pause animation
  ```clojure
  (wait 500)  ; Wait 500ms
  (wait :relative-duration 0.2)  ; Relative to parent
  ```

- `instant`: Zero-duration change
  ```clojure
  (instant 100)  ; Jump to value
  ```

### Composition

#### Sequential Animations (seq)

Run animations one after another:
```clojure
(seq
  (to 0 100 :duration 1000)
  (wait 500)  ; Pause for 500ms
  (to 100 0))
```

#### Parallel Animations (par)

Run multiple animations simultaneously:
```clojure
(par
  :opacity (to 0 1)
  :offset (to 0 100))
```

### Timing Control

#### Duration
Motion supports duration definition in absolute or relative terms.
```clojure
(to 100 :duration 1000)  ; 1 second
(with {:duration 2000} (to 0 100))  ; 2 seconds
(seq {:duration 1000}  ; Total 1 second
  (to 50 :relative-duration 0.3)   ; Takes 300ms
  (to 100 :relative-duration 0.7)) ; Takes 700ms
```
Add a delay before animation starts:
```clojure
(delay 500 (to 100))  ; Wait 500ms then animate
(with {:delay 1000} (to 100))  ; Alternative syntax
```

Note when motions are drived by an external `Animation` absolute duration setted in the motion can be ignored, only `motion-controller` respect the duration.\
So prefer relative duration when the animation is unknown.

### Easing & Curves

Add natural motion with easing curves:
```clojure
(to 100 :curve :ease-in-out)
(with {:curve :ease-out} (to 0 100))
```
Curve may be a `Curve` instance or a keyword or a function.

`flutter-cljd/curves` namespace provides a set of predefined curves.

### Repetition

#### repeat
Repeat an animation multiple times:
```clojure
(repeat 3 (to 0 100))  ; Animate 3 times
```

#### autoreverse
Play animation forward then reverse:
```clojure
(autoreverse (to 0 100))  ; 0->100->0
```

#### tile
Repeat to fill parent duration:
```clojure
(seq {:duration 2000}
  (tile (to 0 360 :duration 500))) ; Rotates 4 times
```

### Side Effects

Trigger actions during animation:
```clojure
(seq
  (to 100)
  (action! :feedback HapticFeedback.selectionClick)
  (to 0))
```

### Synchronization

#### synced
Sync animation with system time to ensure all widgets instances across the app are in sync:
```clojure
(widget
  :managed [controller (motion-controller 
                        vsync
                        (synced (to 0 360 :duration 1000)))]
  (->> (image "spinner.png")
       (animated controller rotate)
       (on-appear #(.repeat controller))))
```

## `animated` Widget

The `animated` widget can be used in two ways to create animations in Flutter:

### 1. Implicit Animations

Implicit animations automatically animate between property changes using a tween animation. This is the simpler way to create animations:

```clojure
;; Basic implicit animation
(->> (text "Hello")
     (animated opacity opacity-value))

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


## Tips & Best Practices

1. Use `:managed` for controllers to ensure proper cleanup

2. Prefer composition over complex single animations:
   ```clojure
   ;; Good
   (seq
     (to 0 50)
     (wait 200)
     (to 50 100))
   
   ;; Avoid
   (to 0 50 50 100 :duration 1000)
   ```

3. Use relative timing for flexible animations:
   ```clojure
   (seq {:duration 1000}
     (to 50 :relative-duration 0.3)
     (to 100 :relative-duration 0.7))
   ```

4. Add curves for natural motion:
   ```clojure
   (to 100 :curve :ease-out)  ; More natural than linear
   ```

5. Use `synced` for coordinated animations across widgets

6. Leverage side effects for feedback:
   ```clojure
   (seq
     (to 100)
     (action! :feedback HapticFeedback.selectionClick))
   ```

7. Consider performance with many simultaneous animations

### Animation Not Running
- Check that controller is created with proper vsync
- Verify controller is started (.forward, .repeat, etc.)
- Ensure widget is mounted when starting animation

### Jerky Animation
- Avoid expensive operations during animation
- Use simpler curves if needed
- Consider reducing number of parallel animations

### Memory Leaks
- Always use `:managed` for controllers
- Dispose controllers when no longer needed
- Stop animations when widget is disposed
