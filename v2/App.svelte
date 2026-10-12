<script>
	import { onMount } from 'svelte'
	import routes from './routes.js'

	const base = 'https://cheekycms.fly.dev/'

	let value = $state(base + routes.health)
	let request = $state({ tag: 'idle' })
	let activeController

	async function load(url) {
		activeController?.abort()
		const controller = new AbortController()
		activeController = controller
		const startedAt = performance.now()

		value = url
		request = { tag: 'loading' }

		try {
			const response = await fetch(url, { signal: controller.signal })

			if (!response.ok) {
				throw new Error(`Request failed: ${response.status}`)
			}

			const data = await response.json()

			if (controller.signal.aborted) return

			request = {
				tag: 'success',
				data,
				elapsed: performance.now() - startedAt,
				status: response.status,
				statusText: response.statusText
			}
		} catch (cause) {
			if (controller.signal.aborted) return

			request = {
				tag: 'failure',
				message: cause instanceof Error ? cause.message : 'Request failed'
			}
		}
	}

	onMount(() => {
		load(value)
		return () => activeController?.abort()
	})
</script>

<main class="min-h-screen bg-zinc-950 px-4 py-10 text-zinc-100 sm:px-6">
	<div class="mx-auto max-w-4xl">
		<header class="mb-8">
			<p class="mb-2 text-xs font-semibold uppercase tracking-[0.25em] text-fuchsia-400">
				CheekyCMS
			</p>
			<h1 class="text-3xl font-bold tracking-tight sm:text-4xl">API Explorer</h1>
			<p class="mt-3 text-zinc-400">
				Choose an endpoint to inspect its live response.
			</p>
		</header>

		<section class="overflow-hidden rounded-2xl border border-zinc-800 bg-zinc-900 shadow-2xl">
			<div class="border-b border-zinc-800 p-4 sm:p-5">
				<label for="route" class="mb-2 block text-sm font-medium text-zinc-300">
					Endpoint
				</label>

				<div class="flex items-center gap-3">
					<select
						id="route"
						value={value}
						onchange={(event) => load(event.currentTarget.value)}
						class="min-w-0 flex-1 rounded-lg border border-zinc-700 bg-zinc-950 px-3 py-2.5 text-sm text-zinc-100 outline-none transition focus:border-fuchsia-500 focus:ring-2 focus:ring-fuchsia-500/20"
					>
						{#each Object.entries(routes) as [label, url]}
							<option value={base.concat(url)}>{label}</option>
						{/each}
					</select>

					<span
						class={[
							'h-2.5 w-2.5 shrink-0 rounded-full',
							request.tag === 'loading' ? 'animate-pulse bg-amber-400' : request.tag === 'failure' ? 'bg-red-400' : request.tag === 'success' ? 'bg-emerald-400' : 'bg-zinc-500'
						]}
						aria-label={request.tag === 'loading' ? 'Loading' : request.tag === 'failure' ? 'Error' : request.tag === 'success' ? 'Ready' : 'Idle'}
					></span>
				</div>

				<p class="mt-3 truncate font-mono text-xs text-zinc-500">{value}</p>
			</div>

			<div class="min-h-80">
				<div class="flex items-center justify-between border-b border-zinc-800 px-4 py-3 sm:px-5">
					<span class="text-xs font-semibold uppercase tracking-wider text-zinc-500">
						Response
					</span>

					{#if request.tag === 'success'}
						<span class="font-mono text-zinc-500">
							{Math.round(request.elapsed)} ms
						</span>
					{/if}

					{#if request.tag === 'loading'}
						<span class="text-xs text-amber-400">Loading…</span>
					{:else if request.tag === 'failure'}
						<span class="text-xs text-red-400">Request failed</span>
					{:else if request.tag === 'success'}
						<span class="text-xs text-emerald-400">{request.status} {request.statusText}</span>
					{/if}
				</div>

				{#if request.tag === 'failure'}
					<div class="p-5 text-sm text-red-300">{request.message}</div>
				{:else if request.tag === 'success'}
					<pre class="whitespace-pre-wrap break-words p-4 font-mono text-sm leading-6 text-zinc-300 sm:p-5">{JSON.stringify(request.data, null, 2)}</pre>
				{/if}
			</div>
		</section>
	</div>
</main>
