<script>
import { ref, watch, onMounted } from 'vue'

export default {
    name: 'Settings',
    setup() {
        const loadingOffset = ref(0)

        const saveLoadingOffsetToLocalStorage = () => {
            localStorage.setItem('loadingOffset', loadingOffset.value)
        }

        // Get the loadingOffset value from local storage
        const getLoadingOffsetFromLocalStorage = () => {
            return parseInt(localStorage.getItem('loadingOffset') || 0)
        }

        // Watch for changes to the loadingOffset value and save them to local storage
        watch(loadingOffset, () => {
            saveLoadingOffsetToLocalStorage()
        })

        // Set the initial value of loadingOffset based on local storage
        loadingOffset.value = getLoadingOffsetFromLocalStorage()

        // Open the settings details element if loadingOffset is not 0
        onMounted(() => {
            if (loadingOffset.value !== 0) {
                document.getElementById('settings').open = true
            }
        })

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
