(ns hooks.hooks
  (:require [clj-kondo.hooks-api :as hooks]))

(def directive-keys
  #{:key :let :get :bind :vsync :managed :keep-alive :watch :bg-watcher
    :spy :context :padding :color :width :height})

(defn- handle-directives
  "Process directives and ensure correct bindings and forms are passed through."
  [children]
  (let [directives-count (* 2 (count (take-while #(hooks/keyword-node? (first %)) (partition 2 children))))]
    {:directives (take directives-count children)
     :forms (drop directives-count children)}))

(defn widget->>-hook
  "Custom hook for `widget->>` macro, which processes directives and threads the rest."
  [{:keys [node]}]
  (let [
        {:keys [directives forms]} (handle-directives (rest (:children node)))
        node (hooks/list-node
              (list*
               (hooks/token-node 'widget)
               directives
               (hooks/list-node
                (list*
                 (hooks/token-node '->>)
                 forms))))]
    (prn node)
    {:node node}))
