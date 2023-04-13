<script setup>
import HelloWorld from './components/HelloWorld.vue'
import axios from 'axios'
import { ref, onMounted } from 'vue'

const movieList = ref([])
// const currentPage = ref(1)
const actor1 = ref('50 Cent')
const actor2 = ref('Miranda Hart')
const actorsCommonFilms = ref({})
const actorPictures = ref([])
const showImages = ref(false)
const isLoading = ref(false)

//why const and anonymous function?

const queryParams = {
  params: {
    api_key: "c92bac37a196e6559bcb667ecb49b1e1",
  },
}

// const genericDatabaseQuery = (typeOfQuery, queryTerm, query) => {
//   const urlRequest = axios.get(
//     `https://api.themoviedb.org/3/${typeOfQuery}/${queryTerm}/query="${query}"}`, queryParams
//   )
// }

const getActorIdFromName = async (actorName) => {
  //search tmdb for actor name and return their id

  const idPromise = await axios.get(
    `https://api.themoviedb.org/3/search/person?query="${actorName}"`, queryParams
  )
  if (idPromise.data.results.length === 0) {
    console.log("no results")
    //set is loading to false
    isLoading.value = false
    //alert user that no results were found for actorname
    alert(`No results found for ${actorName}. Please check the spelling and try again.`)
  }
  // return the promise
  return idPromise
}
const getMovieCreditsByActorId = async (actorId) => {

  // return the promise
  return axios.get(
    `https://api.themoviedb.org/3/person/${actorId}/movie_credits`, queryParams
  )
}
const generateImageLink = (imagePath) => {
  return `https://image.tmdb.org/t/p/w500${imagePath}`
}

const getActorFilmography = async (actorName) => {

  //get the actor id from the name
  let actorId = await getActorIdFromName(actorName)
  //get photos
  const actorImagePath = actorId.data.results[0].profile_path
  const actorImage = generateImageLink(actorImagePath)
  //push this into an array of images, after initially setting it to an empty array
  actorPictures.value = [...actorPictures.value, actorImage]
  //get the movie credits from the actor id
  const movieCredits = await getMovieCreditsByActorId(actorId.data.results[0].id)

  //add external ids to each film object
  movieCredits.data.cast.forEach(async (movie) => {
    const externalIds = await axios.get(`https://api.themoviedb.org/3/movie/${movie.id}/external_ids`, queryParams)
    movie.imdb = externalIds.data.imdb_id
  })
  console.log(movieCredits.data.cast)
  return movieCredits.data.cast
}

const compareBothActorsFilmographies = async (firstActor, secondActor) => {
  //set is loading to true
  isLoading.value = true
  //clear actorpictures array before adding new images
  actorPictures.value = []
  //get the filmographies of both actors and turn them into arrays
  const actor1Filmography = await getActorFilmography(firstActor)
  const actor2Filmography = await getActorFilmography(secondActor)
  const actor1FilmographyIds = actor1Filmography.map(movie => movie.id)
  const actor2FilmographyIds = actor2Filmography.map(movie => movie.id)
  //check films have the same id, then filter the array to only include the common film objects
  let commonFilms = actor1Filmography.filter(movie => actor2FilmographyIds.includes(movie.id))
  //add external ids to each film object
  commonFilms.forEach(async (movie) => {
    const externalIds = await axios.get(`https://api.themoviedb.org/3/movie/${movie.id}/external_ids`, queryParams)
    movie.imdb = externalIds.data.imdb_id
  })
  //check and remove films with duplicate ids (some actors are in films twice)
  commonFilms = commonFilms.filter((film, index, self) =>
    index === self.findIndex((t) => (
      t.id === film.id
    ))
  )
  //now order films by release_date (newest first)
  commonFilms = commonFilms.sort((a, b) => {
    return new Date(b.release_date) - new Date(a.release_date)
  })
  actorsCommonFilms.value = [...commonFilms]
  //set is loading to false
  isLoading.value = false
  console.log(actorsCommonFilms.value, isLoading)
}
const computeGridStyles = () => {
  //if images are shown, add responsive grid classes
  if (showImages.value) {
    return "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 items-end gap-8"
  } else {
    return ""
  }
}
onMounted(() => {
  //run the function on page load
  // compareBothActorsFilmographies(actor1.value, actor2.value)
})
</script>

<template>
  <div class="flex flex-col justify-center dark:text-white p-4">
    <p>This is an extremely rough prototype for an app that tells you which films actors have been in together.</p>
    <div class="flex flex-col justify-center gap-4">
      <transition name="fade">
        <div v-if="isLoading"
          class="absolute top-0 left-0 w-full h-full bg-white dark:bg-black bg-opacity-100 flex flex-col md:flex-row gap-6 justify-center items-center">
          <p class="text-2xl animate-pulse">{{ actor1 }} & {{ actor2 }}</p>
          <img v-for="actor in actorPictures" :src="actor" class="h-64 w-64 rounded-full object-cover animate-spin" />
        </div>
      </transition>
      <label class="dark:text-white flex flex-col gap-2">
        Actor 1
        <input type="text" class="actor actor1 text-black border border-black dark:border-white p-2" v-model="actor1"
          placeholder="Search for an actor" @keyup.enter="compareBothActorsFilmographies(actor1, actor2)" />
      </label>
      <label class="dark:text-white flex flex-col gap-2">
        Actor 2
        <input type="text" class="actor actor2 text-black border border-black dark:border-white p-2" v-model="actor2"
          placeholder="Search for an actor" @keyup.enter="compareBothActorsFilmographies(actor1, actor2)" />
      </label>
      <label class="text-2xl flex">Toggle images? {{ showImages }}
        <input type="checkbox" v-model="showImages" class="ml-4 scale-150"/>
      </label>
    </div>

    <button @click="compareBothActorsFilmographies(actor1, actor2)"
      class="p-4 my-4 border border-black dark:border-white">Compare
      filmographies</button>
    <!-- show list if they have appeared in a film together -->
    <h2 class="text-4xl underline" v-if="actorsCommonFilms.length">These actors <span class="text-xs">(or
        actresses)</span> have been in the
      following {{ actorsCommonFilms.length }}
      {{ actorsCommonFilms.length < 2 ? "film" : "films" }} :</h2>
        <ul v-if="actorsCommonFilms.length" :class="computeGridStyles()" class="p-4">
          <li v-for="film in actorsCommonFilms" :key="film.id" class="group">
            <a :href="`https://www.imdb.com/title/${film.imdb}`">
              <title class="inline-block mb-
                                             text-2xl">{{ film.original_title }}</title>
              <img v-if="showImages" :src=generateImageLink(film.poster_path) :alt="`Movie title: ${film.original_title}`"
                class="md:group-hover:scale-95">
            </a>
          </li>
        </ul>
        <h2 class="text-4xl underline" v-if="actorsCommonFilms == ''"> These actors have not been in a film
          together</h2>
        <div class="border border-black dark:border-white p-4 my-4">
          <details>
            <summary>Current limitations (I won't be fixing these):</summary>
            <ul class="list-disc list-inside">
              <li>The API accepts any string meaning actors can be searched with just one name, e.g. Cruise returns Tom
                Cruise's ID</li>
              <li>While case insensitive, there is no way to handle typos</li>
              <li>The app only searches for the first result returned by the API. If there are multiple actors with the
                exact
                same name, the app will only search for the first result.</li>
              <li>You can search the same person twice</li>

            </ul>
          </details>

          <details>
            <summary>Future improvements:</summary>
            <ul class="list-disc list-inside">
              <li>Overhaul design completely</li>
              <li><span class="line-through">Responsive styles</span> (implemented 29/3/23)</li>
              <li>Carousel display</li>
              <li>Properly obfuscate API key</li>
              <li><span class="line-through">Image toggle, probably with <code class="text-code">v-if</code></span>
                implemented 31/3/23</li>
              <li><span class="line-through">Dark mode toggle using <code
                    class="text-code">@media (prefers-color-scheme)</code></span> implemented 4/4/23</li>
              <li class="line-through">Hyperlink the film titles to the film page on TMBD/imdb</li>
              <li><span class="line-through">Order list by reverse chronology</span>implemented 5/4/23</li>
              <li><span class="line-through">Hard coded "films", there is no handling of a single film being
                  returned</span> implemented 4/4/23</li>
              <li>Show data as a venn diagram(?)</li>
              <li>Allow user to search for more than 2 actors</li>
              <li><span class="line-through">Show user feedback while API query happens ("Searching...")</span>implemented
                13/4/23</li>
              <li><span class="line-through">Fixed bug where double credited actors would show two listings</span></li>
              <li><span class="line-through">The message about the actors not being in a film together is the default condition because the <code
                  class="text-code">v-else</code>
                is hit immediately on pageload (<code class="text-code">actorsCommonFilms</code>, an empty array, is
                truthy
                onload). I will bind this to a check on enter keyup, input focus change and button click. Basically more
                event
                listening.</span>implemented 13/4/23</li>
              <li><span class="line-through">Add error handling for typos/no results</span>implemented 13/4/23</li>
              <li><span class="line-through">Interpolate the actors names into the message about them not being in a film
                  together, but only after
                  the previous change. Trying to do this now will incorrectly say <code>$actor1</code> and
                  <code>$actor2</code>
                  haven't appeared in a film together on load</span> implemented 13/4/23</li>
              <li>Increase max limit of actors to compare, as well as other types of roles (Director and actor collabs)
              </li>
            </ul>
          </details>
        </div>
  </div>
</template>

