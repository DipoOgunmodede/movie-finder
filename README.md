# Movie App Challenge

------
## Prerequisites

* Branch off master, prefix the branch with your name e.g. 'movie-app-chester'
* Switch to node v16.13.2

### In local branch

* Run ```npm install``` in command line from project root (folder containing package.json)
* To run project type ```npm run dev``` in command line from project root

### Create movieDB account and generate API key
* Sign Up: https://www.themoviedb.org/signup
* Generate API key here: https://www.themoviedb.org/settings/api (under Request an API key) 
    * Create as developer
    * Accept Terms and Conditions
    * Type of use: Website
    * Fill out rest of fields (I just enter 12345 in most of them rather than actual address details)
    * Copy API key
    * Replace ```<api_key>``` placeholder within axios call in ```src/App.vue``` with API key


## What's in the box
------

* Vue3
* Vite (this is similar to Gulp)
* Tailwind
* Axios (With example call to movie DB API in APP.vue)

## The challenge

Build a app using the movie database API that does the following:

* Create a card list of popular movies (https://developers.themoviedb.org/3/movies/get-popular-movies)
* Each card should show image + description
* On click of card show modal with extra information e.g. runtime, genre, synopsys
* Add load more button pushes more results into the movie list
* Use tailwind to style - get as creative as you like :) 
* Make use of single file components: https://vuejs.org/guide/scaling-up/sfc.html 
* Add transitions (e.g. for when modal shows, or more results are loaded): https://vuejs.org/guide/built-ins/transition.html

**API Docs**: https://developers.themoviedb.org/3/getting-started/introduction

**Vue Docs**: https://vuejs.org/guide/introduction.html 

## Tips

* Make use of Vue Dev tools browser extension
* Make use of in-build vue features e.g. v-for, v-click, single file components
* Split out into as many components as possible (modal, cards, paging)
* For paging pay attention to the API call (you could replace the hard coded page number with something dynamic...)
* Read the API docs above
* Make use of array methods e.g. .push to add more movies to our results