# Atlantic Taxi Tracker

An installable, offline-first web app for recording taxi rides, shift totals, reports and yearly earnings.

## Put it on your Android phone

A Progressive Web App needs to be hosted at an HTTPS address to install and use its offline service worker. The ZIP contains the app files; it is not an APK.

1. Extract this ZIP on your computer.
2. Upload the contents of the `atlantic_taxi_tracker` folder to a static HTTPS host (for example, your own website or a static hosting provider).
3. Open the HTTPS link in Chrome on your Android phone.
4. Use Chrome's menu → **Install app** or **Add to Home screen**.
5. Open Atlantic Taxi Tracker from your home screen.

You can also test it on a computer by serving this folder through a local web server; opening `index.html` directly with `file://` will not enable PWA installation/offline caching.

## Features
- Start and end shifts; each shift is saved with date and times.
- Record pickup, drop-off, fare, optional tip and notes for each passenger.
- Live shift totals, passenger count, average fare and tips.
- Share a shift summary through Android's share sheet / messaging apps, or use the configured SMS number.
- Generate a PDF report (requires an internet connection the first time the PDF library is loaded).
- Search shift history by year and month; reopen ride details and share old reports.
- Yearly and monthly earnings breakdown.
- Export full JSON backup and CSV ride ledger; import a JSON backup.
- App shell works offline after the first successful load and service-worker cache setup.

## Important data note
Records are stored locally in the browser on that phone. They are not automatically synced to another device or sent to your boss. Export backups regularly. Clearing Chrome site data or uninstalling/resetting the browser may erase local records.

## PDF note
The PDF generator loads jsPDF from a CDN. For PDF creation, connect to the internet at least once so the library can load. Text sharing and recording rides do not depend on that library.

## Atlantic Cab Drivers Manifest format
The current shift screen includes cab number, day/night shift, beginning/ending odometer, cash, extras, meter miles, paid miles, oil/transmission checks, and passenger pickup time/location/destination/fare. Each ride can be marked Cash, Card, or Other. PDF and text reports are arranged to follow the supplied Atlantic Cab Drivers Manifest, including the 50% cash calculation plus the $6 lease fee. The app calculates the cash share from rides marked Cash; verify your employer's accounting rules before submitting.

## Correct driver/company split
Metered fares are split 50/50. The driver receives half of metered fares PLUS 100% of tips. The company receives the other half of metered fares. Tips are excluded from the 50/50 split. Both the live dashboard and shift text/PDF reports show these amounts separately. The former generic 50%-of-cash calculation is not used.

## Cab lease
A $9 cab lease is added to the company's amount for every completed shift. Driver pay remains 50% of metered fares plus 100% of tips. Company amount is 50% of metered fares plus the $9 lease. Tips are not part of the fare split.


## Meter manifest entry fields
The Current shift page now has a Meter readings & vehicle checks section with beginning and ending fields for odometer, cash, extras, meter miles, paid miles, and trip counter. Each total is calculated automatically. Cab number, day/night shift, oil check and transmission check are saved with the shift and included in text/PDF reports.


## Delete shifts
The shift history includes a Delete shift action. It asks for confirmation before permanently removing the selected shift and its ride records, then refreshes totals and history.


## Atlantic Cab green branding update
The app now uses the supplied green Atlantic Cab logo, a black and emerald-green interface, a matching Android launcher icon, and green/black PDF report header. Upload all updated files including atlantic-cab-logo.png and icon-512.png to the GitHub Pages repository root. The service worker cache version was updated so phones fetch the new design.

Version 10 adds a darkened Atlantic Cab background image and higher-contrast panels, buttons, navigation and form fields for readability.
