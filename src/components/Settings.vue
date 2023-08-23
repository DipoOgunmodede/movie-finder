<script>
import { ref, watch, onMounted } from 'vue'
const loadingOffset = ref(0)

const saveLoadingOffsetToLocalStorage = () => {
    localStorage.setItem('loadingOffset', loadingOffset.value)
}
const getloadingOffsetFromLocalStorage = () => { localStorage.getItem('loadingOffset') }

//watch for changes to the loadingOffset value and save them to localstorage 
watch(loadingOffset, () => {
    saveLoadingOffsetToLocalStorage()
}, { immediate: true })

const checkLocalStorageForSettings = () => {
    if (getloadingOffsetFromLocalStorage() != null) {
        loadingOffset.value = getloadingOffsetFromLocalStorage()
        console.log(`I am being fired by the checkLocalStorageForSettings function and the value of loadingOffset is ${loadingOffset.value}`)
    }
}

const openSettingsCheck = () => {
    //if localstorage values are anything other than the default values, open the details element by default
    const storedLoadingOffset = localStorage.getItem('loadingOffset')
    if (storedLoadingOffset !== 0) {
        loadingOffset.value = storedLoadingOffset
        document.getElementById('settings').open = true
        console.log("I have been checked and the settings details element has been opened")
    }
}

onMounted(loadingOffset, () => {
    checkLocalStorageForSettings()
    openSettingsCheck()
})

watch(loadingOffset, () => {
    saveLoadingOffsetToLocalStorage()
}, { immediate: true })


export default {
    name: 'Settings',
    setup() {
        return {
            loadingOffset
        }
    }
}
</script>
<template>
    <details id="settings">
        <summary>Visual settings</summary>
        <label class="text-xl flex flex-col">Show loading screen for {{ loadingOffset }} additional milliseconds
            <input type="range" v-model="loadingOffset" min="0" max="10000" step="50" class="w-full md:w-1/2" />
        </label>
    </details>
</template> 