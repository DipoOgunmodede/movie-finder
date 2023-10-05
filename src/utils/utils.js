import axios from 'axios'
export const queryParams = {
    params: {
      api_key: "c92bac37a196e6559bcb667ecb49b1e1",
    },
  }
export const getCast = (film) => {
    axios
      .get(`https://api.themoviedb.org/3/movie/${film.id}/credits`, queryParams)
      .then((response) => {
        const castList = response.data.cast.map((actor) => ({
          actorName: actor.name,
          characterName: actor.character,
        }));
        film.castList = castList;
        console.log(castList);
        showingCast.value = true;
      })
      .catch((error) => {
        console.log(error);
      });
  };

  export default {
    queryParams,
    getCast,
  };