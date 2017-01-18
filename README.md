# [Run app here](https://filiph.github.io/prime_finder/)

## This valentine’s day, give a gift of a prime number

Did you know that 2017 is a prime number?

## Origin story

I once gave my wife a prime number. It contains digits from my birthday, her birthday, and the date of our wedding. And it is a prime number, so — you know — it's indivisible.

She said it was romantic. I'm sure she meant it, although, looking back, I think she could have just as well said I was a total nerd. Or a cheapo. Or both.

Anyways, I remembered about this whole thing today when playing around with [Isolates](https://api.dartlang.org/stable/1.21.1/dart-isolate/dart-isolate-library.html). I needed a long-running computation to run so that I could test that it doesn't block the main (UI) thread when running in an Isolate. I knew this was okay on Dart VM (which uses good old threads) but I was only half-sure it also worked on the web. And because [someone asked](https://twitter.com/sur3shg/status/821304340715405312), I just had to figure it out. 

As you can hopefully see, Isolates do work on the web. You should be able to execute searches for your loved ones’ birtdates, important anniversaries and whatnot, and the main thread shouldn't drop a single frame. Isolates on the web are implemented using WebWorkers, so they spawn in a parallel thread. The only exception is very old browsers that don't support WebWorkers. The app should still work, theoretically, but it will be halting to a stop when computing.

## Code

The undocumented, hacked-together-in-one-evening code is [here](https://github.com/filiph/prime_finder). A real app would at least build a simple helper for the message passing between the main isolate and the worker. So, not this. [worker.dart](https://github.com/filiph/prime_finder/blob/master/web/worker.dart) is the WebWorker isolate. Nice thing about it is that it would work just as well in DartVM -- so I could make a command line app or a [iOS/Android mobile app](https://flutter.io/) without touching this file. [app_component](https://github.com/filiph/prime_finder/tree/master/lib) is the main part of the user-facing [AngularDart](https://webdev.dartlang.org/angular) app.

If you want a minimal example of isolates, have a look at [dartlang-italia's samples repo](https://github.com/dartlang-italia/dart-libraries-samples/tree/master/isolate).

— Filip Hracek, Jan 17, 2017  
[Twitter](https://twitter.com/filiphracek), [G+](https://plus.google.com/+filiphracek)