/*
 
//MARK: - Code
 
 TODO: Be careful with Calendar.gregorian/Calendar.current and firstWeekday = 2
 TODO: Replace pickers with pop-up tableViews
 TODO: IF this is imperformant: orderedActivities can be replaced by https://github.com/lukaskubanek/OrderedDictionary
 
//MARK: - Plotting
 TODO: Interpolate with line, show trend (+- %)
 TODO: 2 Plots gleichzeitig (z. B. zum Vergleichen von letzter Woche mit vorletzter Woche, Titel zeigt prozentuale Änderung)
 
//MARK: - Explorer
 TODO: copy photos/videos to/select from camera roll
 TODO: Timer.startDate and self.chosenDate concurrency: Add value of end-start to today's value or make a cut at 23:59:59 (appdelegate significant time change)
 TODO: Search bar
 TODO: Receive attachments from other applications (Voice memo, photo library) via "Copy to/Open in Rival"
 TODO: Notify to input data with alert
 TODO: Goals for every activity, green dot for fulfilled goal in calendar
 BUG: Deleting a folder should stop altogether if name redudance occurs, and not result in single activities duplicated into the parent folder
 BUG: Folder textfield is still active after clicking on done
 TODO: Always enable photo/video/audio button and add calendar with dots to the navigation bar
 TODO: Save tree structure every 10 seconds or change flag in creation/deletion/move?
 TODO: Input field always looks the same -> input prompt optimized for type -> save/abort
 
 //MARK: - Networking
 1. Input username
 2. Create a rival: Select friend from friends list (or add friend first via contacts and request). Create title, select activity, wait for friend
 3. After successfully adding a rival, he will appear in the rival list. If you click on him, a window with plot, chat and a button to see the activity detail of the rival's activity will appear (a modified plot window)
 4. Upload activity data regularly onto a server, after registering the uuid of the user is used to create a folder on the server (the username<->uuid correspondency is not saved on the server)
 TODO: Groups for rivalizing with friends
 TODO: Push message to friend: I played guitar for 2 hours today and recorded a short audio snippet + optional message
 
//MARK: - Ad
 
 Right side - (animated) Plot, use of the app.
 Left side - Video respective to every sentence.
 This is how long it takes me and my friends to run our standard routes. (Tim is doing it, I'm talking to a pretty girl). Tim is improving, I'm too constant. (Tim falls down on the ground and barely manages to press stop before passing out.) I should try to get faster.
 This is how long me and my sister brush our teeth in the morning and at night. I'm barely scratching the minimum in the morning, but at least I'm better than my sister. She will ask strangers to start her apple in no time. (Fade out while strange woman bites into an apple and looks in the camera, wondering if this is a joke)
 This is how much I spent on groceries this week. I spend way too much on weekends. I should cut down on that.
 This is how many time I mastur-
 Ahem. This is Rival. It's a cool App. You should get it.
 
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

//AVPlayer (Video) and AVAudioPlayer (Audio) take URLS instead of Bytestreams. I'm not sure if its feasible to load whole videos to the ram just to avoid reloading them. For now, everything is loaded live from the disk. For Audio and Video, named pipes would be the way to go: https://stackoverflow.com/questions/48229690/how-to-open-data-instead-standart-url-in-avplayer

