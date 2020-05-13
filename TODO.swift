/*
 
//MARK: - Code
 
 TODO: fillList and printList and traverseDirectory should be 1 function
 TODO: Be careful with Calendar.gregorian/Calendar.current and firstWeekday = 2
 TODO: Replace pickers with pop-up tableViews
 TODO: isFirstOrSecond is just stupid, rtfm
 
//MARK: - Plotting
 
 TODO: Input time range: Default: Last 7 days. Default buttons (last (1-3) weeks, this week), last (1, 2, 3, 6) months, this month, this year. Click on date: Manually select date range with DateView (split ranges?). Sum up weeks in month view, months in year view. Compare last week with current week.

 1. Zeitraum auswählen
    1a. Willkürliche Datumsauswahl mit dem Kalender, bei Jahresansicht wird immer der erste Monatstag des kleinsten und letzte Monatstag des größten Datums genommen. In der Jahresansicht kann auch 1 Monat auswählt werden, dann wird der erste bzw. letzte Tag dieses Monats als Anfang bzw. Ende festgelegt. Dafür gibts oben rechts nen Okay Button, der Grau ist solange kein Datum ausgewählt wird.
    1b. Vordefinierte Zeitbereiche: Letzte 7 Tage, diese Woche, letzte Woche, dieser Monat, letzter Monat.
 2. Anzahl der Tage/Wochen/Monate/Jahre berechnen, die der Zeitraum umspannt
    2a. Tage: Ende-Anfang
    2b. Wochen: Solange 1 auf Ende.Woche addieren, bis Ende.Woche in Anfang.Woche liegt
    2c. Monate: Wie 2b.
    2d. Jahre: Wie 2b.
 3. Aus 2. ermitteln, ob eine Granularität angebracht ist oder nicht
    3a. mind. 2 Tage
    3b. mind. 2 Wochen
    3c. mind. 2 Monate
    3d. mind. 2 Jahre
 4. Standardgemäß sind Tage bzw. die zuletzt gewählte Granularität ausgewählt. Nicht mögliche Granularitäten sind ausgegraut
 5. Plot anpassen: Maximal 6 Labels im Format 00.00. passen auf die x-Achse, Nullen ausblenden
 
 Right side - (animated) Plot, use of the app.
 Left side - Video respective to every sentence.
 This is how long it takes me and my friends to run our standard routes. (Tim is doing it, I'm talking to a pretty girl). Tim is improving, I'm too constant. (Tim falls down on the ground and barely manages to press stop before passing out.) I should try to get faster.
 This is how long me and my sister brush our teeth in the morning and at night. I'm barely scratching the minimum in the morning, but at least I'm better than my sister. She will ask strangers to start her apple in no time. (Fade out while strange woman bites into an apple and looks in the camera, wondering if this is a joke)
 This is how much I spent on groceries this week. I spend way too much on weekends. I should cut down on that.
 This is how many time I mastur-
 Ahem. This is Rival. It's a cool App. You should get it.
 
 TODO: 2 Plots gleichzeitig (z. B. zum Vergleichen von letzter Woche mit vorletzter Woche, Titel zeigt prozentuale Änderung)
 
 TODO: Input sources: Symbol for each measurement method, can't mix up methods except: Combined line/bar chart for Time, Float and Int. Combined chart: Combined checkbutton, tap once on first, once on second activity
 TODO: Plot type: Line/Bar/Pie for all 3 options. Pie: 1. Select method 2. Select activities. Line/Bar: Only 1 activity at a time
 
//MARK: - Explorer
 
 TODO: Move activity to other folder
 TODO: Search bar
 TODO: Image attachments: Add images from photo library/record them, view images inside a view controller with date buttons
 TODO: Audio attachments: Record short audio snippets with AVKit
 TODO: Video attachments: Record < 10s videos with AVKit
 TODO: Receive attachments from other applications (Voice memo, photo library) via "Copy to/Open in Rival"
 TODO: Notify to input data with alert
 TODO: Goals for every activity, green dot for fulfilled goal in calendar
 
//MARK: - Networking
 
 TODO: Groups for rivalizing with friends
 
 */

/*
 Template:
 
//MARK: - Types
 
 
 
//MARK: - Properties
 
 

//MARK: - Initialization
 
 
 
//MARK: - Public Methods
 
 
 
//MARK: - Private Methods
 
 
 
//MARK: - Actions
 


//MARK: - Navigation
 
 
 
//MARK: - Delegates
 */
