# Button Widget

The `button` widget provides a universal, customizable button implementation that responds to various touch and hover events.
The main difference to native Flutter button is styling - while Flutter's Material buttons come with predefined styles and themes, this button is completely unstyled by default. This gives you full control over the button's appearance through modifiers and the button context, making it easier to create custom button designs without fighting against existing styles.

## Basic Usage

```clojure
;; Simple button with text
(->> (text "Click me!")
     (button #(println "Button clicked!")))

;; Button with multiple event handlers
(->> (text "Interact with me")
     (button {:on-tap #(println "Tapped")
              :on-long-press #(println "Long pressed")
              :on-hover #(println "Hover: " %)}))
```

## Arguments

The button accepts either:
- A function to be called on tap
- A map of options:

### Event Handlers
- `:on-tap` - Called when button is tapped
- `:on-tap-down` - Called when button is pressed down  
- `:on-tap-up` - Called when tap is released
- `:on-tap-cancel` - Called when tap is canceled
- `:on-double-tap` - Called on double tap
- `:on-long-press` - Called when button is held down
- `:on-secondary-tap` - Called on secondary tap (e.g. right click)
- `:on-secondary-tap-up` - Called when secondary tap is released  
- `:on-secondary-tap-down` - Called when secondary tap begins
- `:on-secondary-tap-cancel` - Called when secondary tap is canceled
- `:on-highlight-changed` - Called when highlight state changes
- `:on-hover` - Called when pointer hovers over button
- `:on-focus-change` - Called when focus state changes

### Configuration
- `:focus-node` - Custom focus node
- `:mouse-cursor` - Mouse cursor to show on hover
- `:key` - Widget key

### Inherited Properties
These can be set via `with-inherited` or passed directly:

- `:enabled` - Whether button is interactive
- `:enable-feedback` - Whether to show visual/haptic feedback
- `:exclude-from-semantics` - Whether to exclude from accessibility tree
- `:can-request-focus` - Whether button can receive focus
- `:autofocus` - Whether button should automatically receive focus

## Button Context

The button provides state information to its child widget via the `:button-context` map:

```clojure
{:context BuildContext        ;; Button's build context
 :state #{:disabled          ;; Set of current states
          :pressed           ;; :pressed when being pressed
          :hovered           ;; :hovered when mouse over
          :focused}          ;; :focused when has keyboard focus
 :prev-state Set            ;; Previous state set
 :local-offset Offset?      ;; Local touch coordinates
 :global-offset Offset?}    ;; Global touch coordinates
```

You can access this context in child widgets:

```clojure
(widget->>
  :get {:button-context ctx}
  :let [pressed? (contains? (:state ctx) :pressed)]
  (text "Click me!")
  (opacity (if pressed? 0.8 1.0)))
```

## Styling

Buttons can be styled using the `with-button-modifier` widget, which accepts a function:

```clojure
(defn custom-style [button {:keys [state]}]
  (let [disabled? (contains? state :disabled)
        pressed? (contains? state :pressed)]
    (->> button
         (opacity (cond 
                   disabled? 0.5
                   pressed? 0.8 
                   :else 1.0)))))

(->> (text "Styled Button")
     (button #(println "Clicked!"))
     (with-button-modifier custom-style))
```

The modifier function receives:
1. The button child widget
2. The button context map

To remove button styling, use `without-button-modifier`.

## Helper Functions

### enabled
Sets the `:enabled` inherited value:
```clojure
(->> button
     (enabled true))  ;; Enable
(->> button
     (enabled false)) ;; Disable
```

### disabled  
Sets the `:enabled` inherited value to false:
```clojure
(->> button
     (disabled))     ;; Same as (enabled false)
(->> button
     (disabled true)) ;; Disable
```

## Best Practices

1. Define modifier functions using `defn` rather than anonymous functions to avoid unnecessary rebuilds

2. Extract complex child widgets that don't depend on button state:
```clojure
;; Less efficient - rebuilds content on every state change
(->> (complex-widget-tree)
     (button on-tap))

;; More efficient - only rebuilds button wrapper
(let [content (complex-widget-tree)]
  (->> content
       (button on-tap)))
```

3. Use `without-button-modifier` when creating reusable button components to avoid style conflicts:

```clojure
(defn my-button [label on-tap]
  (->> (text label)
       (button on-tap)
       (without-button-modifier)))
```

4. Access button context for fine-grained control over appearance:

```clojure
(defn animated-button [child on-tap]
  (widget->>
    :get {:button-context ctx}
    :let [pressed? (contains? (:state ctx) :pressed)]
    child
    (scale (if pressed? 0.95 1.0))
    (button on-tap)))
```
