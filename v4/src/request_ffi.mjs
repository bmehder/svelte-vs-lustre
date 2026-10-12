import { Response } from './request.mjs'

export function createRequestController() {
	return { activeController: undefined }
}

export function start(requestController, url, succeeded, failed) {
	requestController.activeController?.abort()
	const controller = new AbortController()
	requestController.activeController = controller

	const startedAt = performance.now()

	// Effects return immediately; completion becomes a Lustre message.
	void fetch(url, { signal: controller.signal })
		.then(response => {
			if (!response.ok) throw new Error(`Request failed: ${response.status}`)
			return response.json().then(data => {
				const elapsed = performance.now() - startedAt
				if (controller.signal.aborted) return
				const output = JSON.stringify(data, null, 2)
				succeeded(new Response(output, elapsed, response.status, response.statusText))
			})
		})
		.catch(cause => {
			if (controller.signal.aborted) return
			failed(cause instanceof Error ? cause.message : 'Request failed')
		})
		.finally(() => {
			if (requestController.activeController === controller)
				requestController.activeController = undefined
		})
}

export function dispose(requestController) {
	requestController.activeController?.abort()
	requestController.activeController = undefined
}

export function onPageExit(stop) {
	window.addEventListener('pagehide', event => {
		// A cached page keeps its runtime for restoration.
		if (!event.persisted) stop()
	})
}
