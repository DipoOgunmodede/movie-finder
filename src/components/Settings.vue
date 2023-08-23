<template>
    <details id="settings" :open="loadingOffsetValue !== 0">
      <summary>Visual settings</summary>
      <label class="text-xl flex flex-col">
        Show loading screen for {{ loadingOffset }} additional milliseconds
        <input type="range" v-model="loadingOffset" min="0" max="10000" step="100" class="w-full md:w-1/2"
               @input="handleSliderInput" />
      </label>
    </details>
  </template>
  
  <script>
  import { ref, watch, onMounted } from 'vue'
  
  export default {
    props: ['loadingOffsetValue'], // Receive the loadingOffsetValue from the parent component
  
    setup(props, { emit }) {
      const loadingOffset = ref(props.loadingOffsetValue)
      let updateTimeout = null
  
      const saveLoadingOffsetToLocalStorage = () => {
        localStorage.setItem('loadingOffset', loadingOffset.value)
      }
  
      const getLoadingOffsetFromLocalStorage = () => {
        return parseInt(localStorage.getItem('loadingOffset'))
      }
  
      const handleSliderInput = () => {
        clearTimeout(updateTimeout)
        updateTimeout = setTimeout(() => {
          saveLoadingOffsetToLocalStorage()
          emit('update:loadingOffsetValue', loadingOffset.value)
        }, 200); // Adjust the delay as needed
      }
  
      loadingOffset.value = getLoadingOffsetFromLocalStorage()
  
      onMounted(() => {
        if (loadingOffset.value !== 0) {
          document.getElementById('settings').open = true
        }
      })
  
      return {
        loadingOffset,
        handleSliderInput
      }
    }
  }
  </script>
  