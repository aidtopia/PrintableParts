Handheld Button
Adrian McCarthy
2023-30-22

Model for a handheld pushbutton.  It's useful for Halloween prop triggers, nurse call buttons, or trivia game signaling devices.

Designed for a [19mm Daier pushbutton][1], but the implementation supports a variety of round panel-mount buttons using OpenSCAD's Customizer feature.  Check the comments at the bottom of the SCAD file for values that work with some other common button sizes.

The case consists of a top, which is a threaded ring that holds the button.  The top fits into the case with a friction fit, but you can add glue to make it permanent.  Panel-mount buttons often come with a jam nut to secure the button to the underside of the panel.  However, those nuts are usually a bit too large in diameter for a nice handheld fit.  That's why the top is threaded to hold the button.

Both parts print well with Prusa Slicer defaults in PLA or PETG.  The top piece should be printed at 0.2 mm layer height (or better).  The case can be printed at 0.3 mm for a faster print.

There is a brim designed into the case portion to help ensure good adhesion despite the small footprint.  Printing the case upside down was not an option because inner features would become overhangs.  The top piece is printed upside down.

To assemble, screw the button into the top piece.  Feed the cord up through the narrow end of the case.  Make the connections.  Use a cable tie (zip tie) around the cord about 6mm up from the bottom of the case.  This will act as a strain relief.  Tug the cord down until it stops at the strain relief.  Squeeze the top into the case.  To make it permanent, a couple drops of CA glue will secure the two pieces.  Consider adding a blob of hot glue to the cord at the bottom of the case as an extra strain relief and to seal the case against dust and dirt.

The case has space for extra connections.  I used it with two pairs of wires with a flyback protection diode since I'm using it to control an inductive load.  To squeeze two pairs into the bottom, I had to increase the "Cable Diameter" in the Customizer settings.

[1]: https://www.chinadaier.com/19mm-push-button-switch/
