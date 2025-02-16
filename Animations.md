# flutter-cljd/animations

A powerful animation system for Flutter that combines declarative motion descriptions with flexible widget animations.

## Overview

The animation system consists of two main parts:
1. **motions** - Declarative descriptions of how values change over time
2. **animated** - A general-purpose widget for building animations.

## Motions

Motions describe how values change over time. They are used by motion controllers to drive animations.\
`Motion` is an `Animatable` subclass, the main difference is that `Motion` can have an intrinsic duration and `Motion` is designed to be composed with other `Motion` instances.

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

### Simple Animations

The library provides several basic animation primitives:

#### to
Animate the current value to a target:
```clojure
(to 100)  ; Animate to 100
(to 0 50 100 200)  ; Animate through multiple values
(to 0 100 :duration 1000 :curve :ease-in-out)  ; With duration 
(to {:offset 100 :opacity 0.5} 
    {:offset 0 :opacity 1.0})  ; Complex values can be animated as well
```

#### from-to 
Explicitly specify start and end values:
```clojure
(from-to 0 100)  ; Animate from 0 to 100
(from-to 0 50 100)  ; From 0 through multiple values
```

#### const
Create discrete value changes:
```clojure
(const 100)  ; Stay at 100
(const 0 50 100)  ; Step through values
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

### Value Transformation

#### map-motion
Transform animated values:
```clojure
(map-motion inc (to 0 10))  ; Animates 1->11
(map-motion int (to 0.0 10.0))  ; Discrete steps
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

## Common Patterns

### Fade In/Out
```clojure
(seq
  (to {:opacity 0.0 :scale 0.8})  ; Initial state
  (par {:duration 300}
    :opacity (to 1.0)
    :scale (to 1.0 :curve :ease-out)))
```

### Loading Spinner
```clojure
(widget
  :managed [rotation (motion-controller
                      vsync
                      (synced (to 0 360 :duration 1000)))]
  (->> (circular-progress-indicator)
       (animated rotation rotate)
       (on-appear #(.repeat rotation))))
```

### Sequence with Feedback
```clojure
(seq
  (to 0 100 :duration 300)
  (action! :feedback HapticFeedback.selectionClick)
  (wait 200)
  (to 100 0 :duration 300))
```

### Staggered List Items
```clojure
(widget
  :let [make-item (fn [i]
          (->> (list-item)
               (animated
                 (delay (* i 100)
                   (seq
                     {:opacity 0.0 :offset 50.0}
                     (par :opacity (to 1.0)
                          :offset (to 0.0 :curve :ease-out))))
                 (fn [opacity offset]
                   (-> (opacity opacity)
                       (offset 0 offset))))))]
  (list-view
    (for [i (range 10)]
      (make-item i))))
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
