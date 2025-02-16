# Flutter ClojureDart Animations

A powerful animation library for Flutter that provides a declarative way to create complex animations with minimal code.

## Key Features

- Declarative animation composition
- Rich set of animation primitives
- Seamless integration with Flutter widgets
- Type-safe animations
- Efficient animation scheduling
- Side-effect support
- Time-based synchronization

## Basic Concepts

### Motion Controllers

Motion controllers manage the lifecycle and playback of animations:

```clojure
(widget
  :managed [controller (motion-controller vsync (to 0 100))]
  (->> (text "Animated")
       (animated controller opacity)))
```

### Simple Animations

The library provides several basic animation primitives:

#### to
Animate to one or more values:
```clojure
(to 100)  ; Animate to 100
(to 0 50 100)  ; Animate through multiple values
(to 0 100 :duration 1000)  ; With duration in milliseconds
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
Set how long an animation runs:
```clojure
(to 100 :duration 1000)  ; 1 second
(with {:duration 2000} (to 0 100))  ; 2 seconds
```

#### Delay
Add a delay before animation starts:
```clojure
(delay 500 (to 100))  ; Wait 500ms then animate
(with {:delay 1000} (to 100))  ; Alternative syntax
```

#### Relative Timing
Time animations relative to parent duration:
```clojure
(seq {:duration 1000}  ; Total 1 second
  (to 50 :relative-duration 0.3)   ; Takes 300ms
  (to 100 :relative-duration 0.7)) ; Takes 700ms
```

### Easing & Curves

Add natural motion with easing curves:
```clojure
(to 100 :curve :ease-in-out)
(with {:curve :ease-out} (to 0 100))
```

Available curves include:
- :linear
- :ease-in
- :ease-out
- :ease-in-out
- :bounce-in
- :bounce-out
- :elastic-in
- :elastic-out

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
Sync animation with system time:
```clojure
(widget
  :managed [controller (motion-controller 
                        vsync
                        (synced (to 0 360 :duration 1000)))]
  (->> (image "spinner.png")
       (animated controller rotate)
       (on-appear #(.repeat controller))))
```

## Common Patterns

### Fade In/Out
```clojure
(seq
  {:opacity 0.0 :scale 0.8}  ; Initial state
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

## Common Issues

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

## Contributing

Contributions are welcome! Please check the GitHub repository for guidelines.

## License

This library is available under the MIT License.
