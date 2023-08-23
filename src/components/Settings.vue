<template>
    <details id="settings" :open="loadingOffsetValue !== 0">
        <summary>Visual settings</summary>
        <label class="text-xl flex flex-col">
            Show loading screen for {{ loadingOffset }} additional milliseconds
            <input type="range" v-model="loadingOffset" min="0" max="10000" step="50" class="w-full md:w-1/2" />
        </label>
    </details>
</template>

<script>
import { ref, watch, onMounted } from 'vue'

export default {
    props: ['loadingOffsetValue'], // Receive the loadingOffsetValue from the parent component
    
    setup(props, { emit }) {
        const loadingOffset = ref(props.loadingOffsetValue)

        const saveLoadingOffsetToLocalStorage = () => {
            localStorage.setItem('loadingOffset', loadingOffset.value)
        }

        const getLoadingOffsetFromLocalStorage = () => {
            return parseInt(localStorage.getItem('loadingOffset'))
        }
        
        const debouncedSave = () => {
            clearTimeout(debounceTimeout)
            debounceTimeout = setTimeout(saveLoadingOffsetToLocalStorage, 300)
        }

        watch(loadingOffset, () => {
            saveLoadingOffsetToLocalStorage()
            // Emit the updated loadingOffset value to the parent component
            emit('update:loadingOffsetValue', loadingOffset.value)
        })

        loadingOffset.value = getLoadingOffsetFromLocalStorage()

        onMounted(() => {
            if (loadingOffset.value != 0) {
                document.getElementById('settings').open = true
            }
        })

        return {
            loadingOffset
        }
    }
}
</script>
