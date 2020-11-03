# Dif(fuser) for Swift and Java

![lifecycle: alpha](https://img.shields.io/badge/lifecycle-alpha-a0c3d2.svg)

Dif(fuser) is a library for Swift and Java that simplifies reacting to changes in data, and gathering events from multiple sources into a single event stream. It achieves this by using a DSL that allows you to declaratively define a relationships between data and side-effects.

The primary use case for this library is to spread out (diffuse) data into the UI of a mobile app, updating only the parts that have changed, and to gather (fuse) events from the UI into a single event stream. This makes it very suitable as a way to interact with the UI in MVI and other similar unidirectional data flow patterns.

This README provides a brief overview - to learn more, read the [wiki](/../../wiki).

## What problem does it solve?

When building applications using unidirectional data flow patterns, we usually prefer to express our business logic in terms of pure functions on immutable data. However, existing libraries and UI frameworks in Android and iOS are typically built around imperative APIs. The Dif(fuser) is designed to bridge these two worlds in a declarative fashion.

This library contains two components:

* `Diffuser`: A way to bind different parts of an immutable data type to different parts of a UI.
* `Fuser`: A way to describe how user interaction events (such as taps and pinches) should be translated into a stream of immutable events.

Simply put, the `Diffuser` maps data into your view, and the `Fuser` extracts events from your view.

## Declaring how data should be rendered
As an example, let's assume you have modelled the UI of your application with the following data structure:
```swift
struct Model {
    let header: Header
    let body: List<String>
}
struct Header {
    let title: String
    let subtitle: String
}
```

Any changes in this model should result in the corresponding part of your UI changing. The Diffuser lets you define these relationships by declaring how to **map** different parts of the data **into** the UI.
```swift
let diffuser = Diffuser<Model>(
    .map(\Model.header, .intoAll(
        .map(\Header.title, .intoText(views.header.title)),
        .map(\Header.subtitle, .intoText(views.header.subtitle))
    )),
    .map(\Model.body, .intoList(views.list))
)
```

You can now use this Diffuser to render your UI:
```swift
diffuser.run(model1) // renders entire UI
diffuser.run(model2) // only re-renders the changes between model1 and model2
diffuser.run(model3) // only re-renders the changes between model2 and model3
```

## Extending the Diffuser
This library includes utility functions for common view manipulations in Android and iOS. However, it is likely that you will want to write your own extensions at some point. Luckily, this is very easy to do since the API of the Diffuser is intentionally just made up of stand-alone functions, i.e. functions which are not tied to an instance of a class.

Let's for example say that you want to update the text of your own custom view class. The easiest way to do this is to use `into` and define a lambda function, which will be called whenever the text changes:
```swift
.map(\Model.stringField, .into { text in
    yourView.setText(text)
    yourView.invalidateLayout()
})
```

If you however want to make this reusable, you can easily encapsulate this into a function instead and give it a name eg. `intoText`:
```swift
func intoText(textView: YourTextView) -> Diffuser<String> {
    return .into { text in
        textView.setText(text)
        textView.invalidateLayout()
    }
}
```

You can now use use this just like any of the built-in Diffuser functions:
```swift
.map(\Model.stringField, intoText(yourTextView))
```

---

# Fuser
Conceptually, the Diffuser lets you define how data should be spread out. In contrast to this, the Fuser allows you to define how events should be gathered. It allows you to merge multiple event sources and transform their outputs in a uniform manner.

## Listening to your UI
As an example, consider that you are implementing the login screen of your application. The user's interactions with your UI components will generate events which some other part of your system wants to know about. For example, tapping the "login" button should generate an event which, when handled, validates the user's input and calls a backend service. For each UI component you will need to remember to start listening for events once your login screen is active, and to stop listening once it becomes inactive. The `Fuser` encapsulates this pattern, and the way you use it is very similar to the `Diffuser`.

Just like with `Diffuser`, you start by creating a structure which defines the relationship between your UI components and your events, but instead of mapping data into the views, you are **extracting** events **from** them:
```swift
let fuser = Fuser<LoginEvent>(
    .extract({ .usernameChanged(username: $0} }, .fromTextChanges(views.username)),
    .extract({ .passwordChanges(password: $0) }, .fromTextChanges(views.password)),
    .extract({ .loginClicked }, .fromTaps(views.login))
)
```
The Fuser provides several extensions for Android and iOS, but it is also simple to write your own if needed.

In order to start listening to events from a fuser, you call the `connect` function:
```swift
let connection = fuser.connect { event in
    // handle events here
}
```

When you are no longer interested in receiving any more events, you have to call `dispose` on the connection that was returned from the call to `connect`:
```swift
connection.dispose()
```

This will in turn dispose all the individual click-listeners etc. that were created when you connected to the fuser.
