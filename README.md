# AsciiSFX
Toying around with the idea of a very small DSL to create sound effects

Target: Swift2, Mac OS X, future use on ios planned

This is work in progress. Expect things to change and you knew it: no documentation yet

Preliminary EBNF:

```
input := oszillator;
oszillator := "S", oszillator_type, oszillator_length, { oszillator_param };
oszillator_type := "I" | "Q" | "W";
oszillator_length := { number };
number := "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9";
hex := "a" | "b" | "c" | "d" | "e" | "f" | number;
notename := "a" | "b" | "c" | "d" | "e" | "f" | "g";
oszillator_param := volume | notes;
volume := 'V', {number};
notes :=  'N', {notename | "-" | "+" | slide};
slide := notename, "/", notename;
```
