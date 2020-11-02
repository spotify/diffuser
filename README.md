# Dif(fuser)

![lifecycle: alpha](https://img.shields.io/badge/lifecycle-alpha-a0c3d2.svg)

Dif(fuser) is a domain-specific language for declaratively defining relationships between data and side-effects. It was primarly designed for working with UIs, but it can be applied in any domain. This README provides a brief overview - to learn more, read the [wiki](/../../wiki).

## What problem does it solve?

When building applications, we like to express our business logic in terms of pure functions on immutable data. However, existing libraries for building UI like the ones provided Android and iOS are built around imperative APIs. The Dif(fuser) is designed to bridge these two worlds in a declarative fashion.

It contains two components:

* `Diffuser`: A way to bind different parts of an immutable model to different parts of a UI.
* `Fuser`: A way to describe how user interaction events (such as taps and pinches) should be translated into a stream of immutable events.

Simply put, the `Diffuser` maps data into your view, and the `Fuser` extracts events from your view.

## Declarative Rendering
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
Any changes in this model should result in the corresponding part of your UI changing. The Diffuser lets you define these relationships:
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
This library provides a set of utility functions for common view manipulations in Android and iOS. However, it is likely that you will want to write your own extensions at some point. Luckily, this is very easy to do since the API of the Diffuser is intentionally just made up of stand-alone functions, i.e. functions which are not tied to the instance of a class.

Let's assume that you wanted to define the `intoText` function for your own custom view class. To do this once, the simplest approach may be to just use a lambda function:
```swift
.map(\Model.stringField, .into { text in
    yourView.setText(text)
    yourView.invalidateLayout()
})
```
However, if you want to re-use this functionality, you can encapsulate it in your own `intoText` function.
```swift
func intoText(textView: YourTextView) -> Diffuser<String> {
    return .into { text in
        textView.setText(text)
        textView.invalidateLayout()
    }
}
```
You can now use use this just like any other Diffuser function:
```swift
.map(\Model.stringField, intoText(yourTextView))
```

---

# Fuser
Conceptually, the Diffuser lets you define how data should enter your system. In contrast to this, the Fuser allows you to define how data should exit your system. It allows you to merge event sources and manipulate their outputs in a uniform manner.

## Listening to your UI
As an example, consider that you are implementing the login screen of your application. The user's interactions with your UI components will generate events which some other part of your system should be responsible for handling. For example, clicking the "login" button should generate an event which, when handled, validates the user's input and calls a backend service. For each UI component you will need to remember to start listening for events once your login screen is active, and to stop listening once it becomes inactive. The fuser provides an abstraction for dealing with this pattern uniformly.

Much like the Diffuser, you start by creating a structure which defines the relationship between your UI components and your events:
```swift
let fuser = Fuser<LoginEvent>(
    .extract({ .usernameChanged(username: $0} }, .fromTextChanges(views.username)),
    .extract({ .passwordChanges(password: $0) }, .fromTextChanges(views.password)),
    .extract({ .loginClicked }, .fromTaps(views.login))
)
```
The Fuser provides several extensions for Android and iOS, but it is also simple to write your own if needed.

In order to handle events, simply call the `connect` function:
```swift
let connection = fuser.connect { event in
    // handle events here
}
```
When you are no longer interested in these events, simply call `dispose` on the object returned by the call to `connect`:
```swift
connection.dispose()
```
This will in turn dispose all the individual click-listeners you created.
