<script setup>
import axios from 'axios'
import { watch } from 'vue'
import { ref, onMounted } from 'vue'
const currentActor = ref('')
const actorsForComparison = ref(['Ben Affleck', 'Matt Damon', 'George Clooney'])
const actorsCommonFilms = ref({})
const actorPictures = ref([])
const showImages = ref(true)
const isLoading = ref(false)
const loadingOffset = ref(0)
//const default settings is true when loading offset isn't 0 and/or show images is false
const queryParams = {
  params: {
    api_key: "c92bac37a196e6559bcb667ecb49b1e1",
  },
}

const addActorName = (actorName) => {
  actorsForComparison.value = [...actorsForComparison.value, actorName];
};

const addActor = () => {
  if (currentActor.value.trim() !== '') {
    addActorName(currentActor.value.trim());
    console.log(actorsForComparison.value)
    currentActor.value = '';
  }
}

const undoActor = () => {
  currentActor.value = actorsForComparison.value[actorsForComparison.value.length - 1]
  actorsForComparison.value.pop();
}


const openSettingsCheck = () => {
  //if localstorage values are anything other than the default values, open the details element
  if (loadingOffset.value !== 0 || showImages.value === false) {
    document.getElementById('settings').open = true
  }
}

//add a method to remove an actor from the array on element click, but keeping the rest
const removeActor = (actorName) => {
  actorsForComparison.value = actorsForComparison.value.filter(actor => actor !== actorName)
}

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
  console.log(movieCredits.data.cast)
  return movieCredits.data.cast
}

const compareActorsFilmographies = async (actorsForComparison) => {
  try {
    // show loading spinner
    isLoading.value = true;
    actorPictures.value = [];

    // get actor filmographies
    const actorFilmographies = await Promise.all(actorsForComparison.map(getActorFilmography));
    console.log(actorFilmographies);

    // find common films by ID
    const commonFilmIds = new Set(actorFilmographies[0].map(movie => movie.id));
    for (let i = 1; i < actorFilmographies.length; i++) {
      const actorFilms = actorFilmographies[i];
      const actorFilmIds = new Set(actorFilms.map(movie => movie.id));
      commonFilmIds.forEach(id => {
        if (!actorFilmIds.has(id)) {
          commonFilmIds.delete(id);
        }
      });
    }

    // get common films with all actors
    const commonFilms = await Promise.all(Array.from(commonFilmIds).map(async commonFilmId => {
      const response = await axios.get(`https://api.themoviedb.org/3/movie/${commonFilmId}`, { ...queryParams, append_to_response: 'external_ids' });
      const { id, title, release_date, poster_path, imdb_id } = response.data;
      return { id, title, release_date, poster_path, imdb_id };
    }));


    // remove duplicate films
    const uniqueCommonFilms = commonFilms.filter((film, index, self) => {
      return index === self.findIndex(otherFilm => otherFilm.id === film.id);
    });


    // sort films by release date (newest first)
    uniqueCommonFilms.sort((a, b) => new Date(b.release_date) - new Date(a.release_date));

    // update state variables
    actorsCommonFilms.value = uniqueCommonFilms;

    //if loading offset is more than 0 add a set timeout to allow the loading animation to finish
    if (loadingOffset.value > 0) {
      setTimeout(() => {
        isLoading.value = false;
      }, loadingOffset.value)
    } else {
      isLoading.value = false;
    }
  } catch (error) {
    console.error(error);
    // handle error by displaying an error message to the user
  }
};

//save showimages, actors for comparison and loadingOffset values to localStorage
const saveLocalStorage = () => {
  localStorage.setItem('loadingOffset', loadingOffset.value)
  localStorage.setItem('showImages', showImages.value)
  localStorage.setItem('actorsForComparison', JSON.stringify(actorsForComparison.value))
}

const checkLocalStorage = () => {
  // check if localStorage items exist
  const loadingOffsetLocalStorage = localStorage.getItem('loadingOffset')
  const showImagesLocalStorage = localStorage.getItem('showImages')
  const actorsForComparisonLocalStorage = localStorage.getItem('actorsForComparison')

  // if localStorage items exist, update the variables with their values
  if (loadingOffsetLocalStorage) {
    loadingOffset.value = Number(loadingOffsetLocalStorage)
  }
  if (showImagesLocalStorage) {
    showImages.value = showImagesLocalStorage === 'true'
  }
  if (actorsForComparisonLocalStorage) {
    actorsForComparison.value = JSON.parse(actorsForComparisonLocalStorage)
  }
}

//update local storage settings every time loadingoffset, showimages or actorsforcomparison changes
watch([loadingOffset, showImages, actorsForComparison], () => {
  saveLocalStorage()
})

onMounted(() => {
  //check if cookies exist
  checkLocalStorage()
  openSettingsCheck()
})

const computeGridStyles = () => {
  //if images are shown, add responsive grid classes
  if (showImages.value) {
    return "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 items-end gap-8"
  } else {
    return ""
  }
}
</script>

<template>
  <div class="flex flex-col justify-center dark:text-white p-4">
    <p>This is an extremely basic prototype for an app that tells you which films actors have been in together.</p>
    <div class="flex flex-col justify-center gap-4">
      <transition name="fade">
        <div v-if="isLoading"
          class="absolute top-0 left-0 w-full h-full bg-white dark:bg-black bg-opacity-100 flex flex-col gap-6 justify-center items-center z-10">
          <ul class="flex flex-col gap-4">
            <li class="animate-pulse block" v-for="actor in actorsForComparison">{{ actor }}</li>
          </ul>
          <img v-for="actor in actorPictures" :src="actor" class="h-48 w-48 rounded-full object-cover animate-spin" />
        </div>
      </transition>
      <section class="flex gap-4 my-4 ">
        <input type="text" class="actor actor2 text-black border border-black dark:border-white p-2 w-2/3"
          v-model="currentActor" @keydown.enter="addActor" placeholder="Add actor">
        <!-- add a button that is disabled and visibly greyed out if the input is empty. use a different text colour when it's disabled-->
        <button @click="addActor" :disabled="currentActor.length < 2"
          class="w-1/3 border border-black dark:border-white text-black dark:text-white p-2"
          :class="currentActor.length < 2 ? 'opacity-50 bg-red-700 cursor-not-allowed' : 'bg-green-500'">Add
          actor</button>
      </section>
      <ul v-if="actorsForComparison.length > 0">Actors being searched:
        <li v-for="actor in actorsForComparison" class="list-disc list-inside"><span>{{ actor }} </span> <button
            @click="removeActor(actor)">- Remove this actor</button>
        </li>
      </ul>
      <details id="settings">
        <summary>Visual settings</summary>
        <label class="text-xl flex">Toggle images? {{ showImages }}
          <input type="checkbox" v-model="showImages" class="ml-4 scale-150" />
        </label>
        <label class="text-xl flex flex-col">Show loading screen for {{ loadingOffset }} additional milliseconds
          <input type="range" v-model="loadingOffset" min="0" max="2500" step="100" class="w-full md:w-1/2" />
        </label>
      </details>
    </div>

    <button @click="compareActorsFilmographies(actorsForComparison)"
      class="p-4 my-4 border border-black dark:border-white">Compare
      filmographies</button>
    <!-- show list if they have appeared in a film together -->
    <h2 class="text-4xl underline" v-if="actorsCommonFilms.length">These actors <span class="text-xs">(or
        actresses)</span> have been in the
      following {{ actorsCommonFilms.length }}
      {{ actorsCommonFilms.length < 2 ? "film" : "films" }} :</h2>
        <ul v-if="actorsCommonFilms.length" :class="computeGridStyles()" class="p-4">
          <li v-for="film in actorsCommonFilms" :key="film.id" class="group">
            <a :href="`https://www.imdb.com/title/${film.imdb_id}`">
              <title class="inline-block mb-2 text-2xl">{{ film.original_title }}</title>
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
              <li><span class="line-through">The message about the actors not being in a film together is the default
                  condition because the <code class="text-code">v-else</code>
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
              <li><span class="line-through">show loading screen for longer before showing results</span> implemented
                13/4/23</li>
              <li>Implement vue draggable to drag actors into a "bucket" for comparison - vue sortable</li>
            </ul>
          </details>
        </div>
  </div>
  <small class="text-black dark:text-white">Images provided by <a href="https://www.themoviedb.org/">TMDB</a></small>
  <a href="https://www.flaticon.com/free-icons/film" title="film icons">Film icons created by bukeicon - Flaticon</a>
</template>

