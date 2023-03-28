<script setup>

import HelloWorld from './components/HelloWorld.vue'
import axios from 'axios'

import { ref, onMounted } from 'vue'

const movieList = ref([])
// const currentPage = ref(1)
const actor1 = ref('Matt Damon')
const actor2 = ref('Ben Affleck')
const actors = ref([])
const actorsCommonFilms = ref({})
const actor1Filmography = ref([])

const getPopularMovieList = () => {
  axios.get('https://api.themoviedb.org/3/movie/popular?api_key=c92bac37a196e6559bcb667ecb49b1e1&language=en-US&page=1')
    .then(function (response) {
      // Check out the console to see the results
      movieList.value = response.data.results
    })
    .catch(function (error) {
      // handle error
      console.log(error);
    })
}

//can I turn this into a venn diagram?
//why const and anonymous function?

const queryParams = {
  params: {
    api_key: "c92bac37a196e6559bcb667ecb49b1e1",
  },
}

const genericDatabaseQuery = (typeOfQuery, queryTerm, query) => {
  const urlRequest = axios.get(
    `https://api.themoviedb.org/3/${typeOfQuery}/${queryTerm}/query="${query}"}`, queryParams
  )
}

const getActorIdFromName = (actorName) => {
  //search tmdb for actor name and return their id
  return axios.get(
    `https://api.themoviedb.org/3/search/person?query="${actorName}"`, queryParams
  )
}

const getMovieCreditsByActorId = (actorId) => {
  // return the promise
  return axios.get(
    `https://api.themoviedb.org/3/person/${actorId}/movie_credits`, queryParams
  )
}

const getActorFilmography = async (actorName) => {
  //get the actor id from the name
  let actorId = await getActorIdFromName(actorName)
  //get the movie credits from the actor id
  const movieCredits = await getMovieCreditsByActorId(actorId.data.results[0].id)
  //return the movie credits
  console.log(movieCredits.data.cast)
  return movieCredits.data.cast
}

const compareBothActorsFilmographies = async (firstActor, secondActor) => {

  //get the filmographies of both actors and turn them into arrays
  const actor1Filmography = await getActorFilmography(firstActor)
  const actor2Filmography = await getActorFilmography(secondActor)

  const actor1FilmographyIds = actor1Filmography.map(movie => movie.id)
  const actor2FilmographyIds = actor2Filmography.map(movie => movie.id)
  //check films have the same id, then filter the array to only include the common film objects
  const commonFilms = actor1Filmography.filter(movie => actor2FilmographyIds.includes(movie.id))
  console.log(commonFilms)
  actorsCommonFilms.value = commonFilms
}
</script>

<template>
  <div class="flex flex-col justify-center text-white px-4">
    <p>This is an extremely rough prototype for an app that tells you which films actors have been in together.</p>


    <details>
      <summary>Current limitations (I won't be fixing these):</summary>
      <ul>
        <li>This looks like absolute shit</li>
        <li>Only 2 actors can be compared at a time</li>
        <li>While case insensitive, there is no way to handle typos</li>
        <li>
          The app only searches for the first result returned by the API. If there are multiple actors with the exact same
          name,
          the app will only search for the first result.
        </li>
        <li>You can search the same person twice</li>

      </ul>
    </details>

    <details>
      <summary>Future improvements:</summary>
      <ul>
        <li>Dark mode toggle using <code class="text-code">@media (prefers-color-scheme)</code></li>
        <li>Hyperlink the film titles to the film page on TMBD/imdb</li>
        <li>Order list by rating</li>
        <li>Hard coded "films", there is no handling of a single film being returned</li>
        <li>Show data as a venn diagram</li>
        <li>Allow user to search for more than 2 actors</li>
        <li>Show user feedback while API query happens</li>
        <li>Show rating for each film</li>
        <li>The message about the actors not being in a film together is the default condition because the <code
            class="text-code">v-else</code>
          is hit immediately on pageload (<code class="text-code">actorsCommonFilms</code> is truthy onload). If I can be
          bothered I will bind this to a check on enter keyup, input focus change and button click. Basically more event listening</li>
        <li>Interpolate the actors names into the message about them not being in a film together</li>
        <li>Increase max limit of actors to compare</li>
      </ul>
    </details>

    <div class="flex flex-col justify-center gap-4">
      <label class="text-white flex flex-col gap-2">
        Actor 1
        <input type="text" class="actor actor1 text-black p-2" v-model="actor1" placeholder="Search for an actor" />
      </label>
      <label class="text-white flex flex-col gap-2">
        Actor 2
        <input type="text" class="actor actor2 text-black p-2" v-model="actor2" placeholder="Search for an actor" />
      </label>
    </div>

    <button @click="compareBothActorsFilmographies(actor1, actor2)" class="p-4 my-4 border border-white">Compare
      filmographies</button>
    <!-- show list if they have appeared in a film together -->
    <ul v-if="actorsCommonFilms.length">
      <h2  class="text-2xl underline">These actors <span class="text-xs">(or actresses 😑)</span> have been in the following {{actorsCommonFilms.length}} films:</h2>
      <li v-for="film in actorsCommonFilms" :key="film.id">
        <a>{{ film.original_title }}</a>
        <img src="" alt="">
      </li>
    </ul>
    <p v-else>These actors have not been in a film together</p>
  </div>
</template>
