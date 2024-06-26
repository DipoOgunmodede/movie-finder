<script setup>
import axios from 'axios'
import { watch } from 'vue'
import { ref, onMounted } from 'vue'
import {getCast, queryParams, getImdbCastLink} from './utils/utils.js'
const currentActor = ref('')
const actorsForComparison = ref(['Ben Affleck', 'Matt Damon', 'George Clooney'])
const actorsCommonFilms = ref({})
const actorPictures = ref([])
const showingCast = ref(false)
const showImages = ref(true)
const isLoading = ref(false)
const loadingOffset = ref(0)
const numberOfCastToShow = 13
//const default settings is true when loading offset isn't 0 and/or show images is false

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

const flipCard = (event) => {
  console.log('card flipped');
  console.log(event);
  // find parent card element
  const card = event.target.closest('.card');
  const cardInner = event.target.closest('.card__inner');
  card.classList.add('inner-is-flipped');
  //remove scrolling from body
  document.body.classList.add('overflow-hidden');
  cardInner.classList.toggle('flipped');
};

// Call flipCard when a card is clicked
const cards = document.querySelectorAll('.card');
cards.forEach((card) => {
  card.addEventListener('click', flipCard);
});


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
  //immediately run comparison if there are more than 1 actors in the array
  if (actorsForComparison.value.length > 1) {
    compareActorsFilmographies(actorsForComparison.value)
  }
  if (actorsForComparison.value.length === 1) {
    actorsCommonFilms.value = []
  }
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
    const uniqueActors = new Set(actorsForComparison);
    if (uniqueActors.size !== actorsForComparison.length) {
      alert('Duplicate actor(s) entered.');
      isLoading.value = false;
      return;
    }
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
      const filmData = response.data;

      // get character names for every actor in the film
      const characterNames = actorFilmographies.map(actorFilms => {
        const movie = actorFilms.find(movie => movie.id === commonFilmId);
        return movie ? movie.character : '';
      });

      return filmData;
    }));

    // remove duplicate films
    const uniqueCommonFilms = commonFilms.filter((film, index, self) => {
      return index === self.findIndex(otherFilm => otherFilm.id === film.id);
    });


    // sort films by release date (newest first)
    uniqueCommonFilms.sort((a, b) => new Date(b.release_date) - new Date(a.release_date));

    // update state variables
    actorsCommonFilms.value = uniqueCommonFilms;
    console.log(actorsCommonFilms.value)
    //if loading offset is more than 0 add a set timeout to allow the loading animation to finish
    if (loadingOffset.value > 0) {
      setTimeout(() => {
        isLoading.value = false;
      }, loadingOffset.value)
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else {
      isLoading.value = false;
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  } catch (error) {
    console.error(error);
    // handle error by displaying an error message to the user
  }
};



const toggleCastVisibility = (filmId) => {
  console.log("button clicked")
  const film = actorsCommonFilms.value.find((film) => film.id === filmId);

  if (!film.castList) {
    getCast(film, showingCast, numberOfCastToShow);

  } else {
    // If cast list exists, simply toggle visibility
    console.log("cast list exists")
    showingCast.value = !showingCast.value;
  }
};


const resetAllCardsAndCastVisiblity = () => {
  //remove card visibility and force card to show front
  document.body.classList.remove('overflow-hidden');
  const allCards = document.querySelectorAll('.card');
  allCards.forEach((otherCard) => {
    otherCard.classList.remove('inner-is-flipped');
    otherCard.querySelector('.card__inner').classList.remove('flipped');
  });
  //hide cast
  showingCast.value = false;

}

const addActorFromCast = (actorName) => {
  const confirmation = confirm(`Do you want to add ${actorName} to the comparison array? (this will immediately run a new search)`);
  if (confirmation) {
    addActorName(actorName);
    //reset all cards and cast visibility
    resetAllCardsAndCastVisiblity();
    //run comparison immediately
    compareActorsFilmographies(actorsForComparison.value)
  }
};

//format large numbers to dollars without decimal places
const formatUSD = (number) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format(number)
}

const transformNamesToTitleCase = (name) => {
  return name.split(' ').map(word => word[0].toUpperCase() + word.slice(1)).join(' ')
}


const transformToLocaleDateString = (dateString) => {
  const date = new Date(dateString);
  return date.toLocaleDateString();
}

//save showimages, actors for comparison values to localStorage
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
    return "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 items-end gap-8"
  } else {
    return ""
  }
}
</script>

<template>
  <div class="flex flex-col justify-center dark:text-white p-4">
    <div class="flex flex-col justify-center gap-4">
      <section class="flex gap-4 my-4 ">
        <input type="text" class="actor actor2 text-black border border-black dark:border-white p-2 w-2/3"
          v-model="currentActor" @keydown.enter="addActor" placeholder="Add actor">
        <!-- add a button that is disabled and visibly greyed out if the input is empty. use a different text colour when it's disabled-->
        <button @click="addActor" :disabled="currentActor.length < 2"
          class="w-1/3 border border-black dark:border-white text-black dark:text-white p-2"
          :class="currentActor.length < 2 ? 'opacity-50 bg-red-700 cursor-not-allowed' : 'bg-green-500'">Add
          actor</button>
      </section>
      <ul class="space-y-2 text-xl" v-if="actorsForComparison.length > 0">Actors being searched:
        <li v-for="actor in actorsForComparison" class="list-disc list-inside text-base space-x-1"><span>{{
          transformNamesToTitleCase(actor) }} </span> <button class="text-red-700" @click="removeActor(actor)"> Remove
            this actor</button>
        </li>
      </ul>
      <details id="settings">
        <summary>Visual settings</summary>
        <label class="text-xl flex flex-col">Show loading screen for {{ loadingOffset }} additional milliseconds
          <input type="range" v-model="loadingOffset" min="0" max="10000" step="50" class="w-full md:w-1/2" />
        </label>
      </details>
    </div>
    <transition name="fade" v-if="isLoading">
      <div
        class="loading-overlay overflow-hidden p-4 fixed inset-0 w-full h-full bg-white dark:bg-black bg-opacity-100 flex flex-col gap-6 justify-items-center z-10">
        <p v-if="actorsForComparison.length > 0">Looking for shared filmography of the following:</p>
        <p>{{ transformNamesToTitleCase(actorsForComparison.join(', ')) }}</p>
        <div class="flex flex-wrap justify-around gap-4">
          <img v-for="actor in actorPictures" :src="actor"
            class="w-32 aspect-square rounded-full object-cover animate-spin-fast duration-100" />
        </div>
      </div>
    </transition>
    <button @click="compareActorsFilmographies(actorsForComparison)"
      class="p-4 my-4 border border-black dark:border-white bg-green-500 disabled:bg-red-700 disabled:cursor-not-allowed"
      :disabled="actorsForComparison.length < 2">Find shared filmography</button>

    <!-- show list if they have appeared in a film together -->
    <h2 class="text-4xl underline" v-if="actorsCommonFilms.length">
      {{
        actorsForComparison.length > 1
        ? actorsForComparison.slice(0, -1).map(actor => transformNamesToTitleCase(actor)).join(', ') +
        ' and ' +
        transformNamesToTitleCase(actorsForComparison.slice(-1)[0])
        : transformNamesToTitleCase(actorsForComparison[0])
      }}
      have been in the following {{ actorsCommonFilms.length }} {{
        actorsCommonFilms.length === 1 ? 'film' : 'films' }}:
    </h2>

    <ul v-if="actorsCommonFilms.length" :class="computeGridStyles()" class="p-4">
      <li v-for="film in actorsCommonFilms" :key="film.id" class="aspect-[2/3]">
        <div class="card w-full h-full" @click="flipCard($event)">
          <div class="card__inner w-full h-full cardTransition">
            <div class="front z-[2]">
              <img :src="generateImageLink(film.poster_path)" :alt="`Movie title: ${film.original_title}`"
                class="md:group-hover:scale-95 w-full">
            </div>
            <div @click.stop="resetAllCardsAndCastVisiblity" class="back h-full w-full bg-cover bg-no-repeat bg-center overflow-hidden p-4"
              :style="{ 'background-image': `url(${generateImageLink(film.poster_path)})` }">
              <div
                class="p-6 w-full h-full bg-[#305252] bg-clip-padding backdrop-filter backdrop-blur-sm bg-opacity-50 border film-information space-y-4 overflow-y-auto">
                <button class="close-button">CLOSE CARD</button>
                <button v-if="!showingCast" class="ml-4 showCast" @click.stop="toggleCastVisibility(film.id)">
                  SHOW CAST
                </button>
                <button v-else class="ml-4 showCast" @click.stop="toggleCastVisibility(film.id)">
                  SHOW SYNOPSIS</button>
                <div v-if="!showingCast">
                  <div>
                    <h2 class="text-6xl md:text-3xl 2xl:text-8xl mb-2">{{ film.original_title }}</h2>
                    <p v-if="film.tagline" class="text-xl mb">Tagline: {{ film.tagline }}</p>
                  </div>
                  <div class="">
                    <p>Released on {{ transformToLocaleDateString(film.release_date) }}</p>
                    <p v-if="film.budget > 0">Film budget: {{ formatUSD(film.budget) }}</p>
                    <p v-if="film.revenue > 0">Film revenue: {{ formatUSD(film.revenue) }}</p>
                    <!-- loop over all genres in film.genres -->
                    <p>
                      {{ film.genres.length > 1 ? 'Genres:' : 'Genre:' }}
                      <span v-for="(genre, index) in film.genres" :key="genre.id">
                        {{ genre.name }}<span v-if="index < film.genres.length - 1">,
                        </span>
                      </span>
                    </p>

                    <p>Runtime: {{ film.runtime + ' minutes' }}</p>
                  </div>
                  <p class="mt-4 md:hidden 2xl:inline ">Synopsis: {{ film.overview }}
                  </p>

                </div>
                <div v-else>
                  <h3 class="text-2xl mb-2">CAST LIST:</h3>
                  <ul>
                    <template v-if="film.castList">
                      <li v-for="(castItem, index) in film.castList.slice(0, numberOfCastToShow)" :key="castItem.actorName"
                        class="text-xl">
                        <span class="cursor-pointer hover:underline" @click="addActorFromCast(castItem.actorName)">
                          {{ castItem.actorName }}
                        </span> as {{ castItem.characterName }}
                      </li>
                      <li v-if="film.castList.length > numberOfCastToShow">
                       <a :href="getImdbCastLink(film)"> and {{ film.castList.length - numberOfCastToShow }} others</a>
                      </li>
                    </template>
                  </ul>

                </div>


              </div>

            </div>

          </div>

        </div>
      </li>
    </ul>



    <h2 class="text-4xl underline"></h2>
    <div class="hidden border border-black dark:border-white p-4 my-4">
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
          <li>Searching for more than like 4-5 actors won't look great cos their images will be cut off by
            <code>overflow:hidden;</code>
          </li>

        </ul>
      </details>

      <details>
        <summary>Future improvements:</summary>
        <li>Add save search functionality</li>
        <li>View cast button</li>
        <li>Add actor button to cast list</li>
        <li>Cast list overflows poorly</li>
        <li>Improve usablity (keyboard shortcuts)</li>
        <ul class="list-disc list-inside">
          <li>Overhaul design completely. It looks even worse on desktop</li>
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
          <li><span class="line-through">Allow user to search for more than 2 actors</span>implemented 18/4/23</li>
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
          <li><span class="line-through">Increase max limit of actors to compare,</span> as well as other types of roles
            (Director and actor collabs)
          </li>
          <li><span class="line-through">show loading screen for longer before showing results</span> implemented
            13/4/23</li>
          <li>Implement vue draggable to drag actors into a "bucket" for comparison - vue sortable</li>
        </ul>
      </details>
    </div>
  </div>
  <small class="text-black dark:text-white">Images provided by <a href="https://www.themoviedb.org/">TMDB</a></small>
</template>