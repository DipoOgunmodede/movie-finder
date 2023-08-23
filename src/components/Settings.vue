<template>
    <details id="settings" open="loadingOffsetValue !== 0">
        <summary>Visual settings</summary>
        <label class="text-xl flex flex-col">
            Show loading screen for {{ loadingOffset }} additional milliseconds
            <input type="range" v-model="loadingOffset" @input="handleSliderInput" min="0" max="10000" step="50" class="w-full md:w-1/2" />
        </label>
    </details>
</template>

<script>
import { ref, onMounted } from 'vue'

export default {
    props: {
        loadingOffsetValue: {
            type: Number,
            default: 0
        }
    },
    
    setup(props, { emit }) {
        const loadingOffset = ref(props.loadingOffsetValue)
        let inputTimeout

        const saveLoadingOffsetToLocalStorage = () => {
            localStorage.setItem('loadingOffset', loadingOffset.value)
        }

        const getLoadingOffsetFromLocalStorage = () => {
            return parseInt(localStorage.getItem('loadingOffset')) || 0
        }

        const handleSliderInput = () => {
            clearTimeout(inputTimeout)
            inputTimeout = setTimeout(() => {
                saveLoadingOffsetToLocalStorage()
                emit('update:loadingOffsetValue', loadingOffset.value)
            }, 300)
        }

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
