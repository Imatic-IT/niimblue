<script lang="ts">
  import { onMount } from "svelte";
  import MdIcon from "../basic/MdIcon.svelte";
  import { type ExportedLabelTemplate } from "../../types";
  import { LocalStoragePersistence } from "../../utils/persistence";
  export let onLoadRequested: (label: ExportedLabelTemplate) => void;
  export let mantisData: { templateUrl: string };

  const GITHUB_TOKEN = import.meta.env.VITE_IMATIC_GITHUB_TOKEN;
  const GITHUB_API_URL = import.meta.env.VITE_GITHUB_REPO_API_URL;
  const GITHUB_RAW_URL = import.meta.env.VITE_GITHUB_REPO_RAW_URL;

  const isEnvConfigured = Boolean(GITHUB_TOKEN) && Boolean(GITHUB_API_URL) && Boolean(GITHUB_RAW_URL);

  let usedSpace: number = 0;
  let isDropdownOpen = false;
  let isLoading = false;

  let templates: string[] = [];
  let selectedTemplate: string | null = null;
  let isLoadingTemplates = false;
  let templatesError = "";
  let isLoadingTemplateContent = false;
  let templateError = "";
  let url = new URL(mantisData.templateUrl);

  async function openDropdown() {
    isDropdownOpen = true;
    isLoading = true;
    await fetchTemplatesFromGithub();
    isLoading = false;

    if (!selectedTemplate) {
      selectedTemplate = url.searchParams.get("templateId") + ".json";
    }
  }

  interface GithubContentItem {
    type: string;
    name: string;
  }

  const calcUsedSpace = () => {
    usedSpace = LocalStoragePersistence.usedSpace();
  };

  const fetchTemplatesFromGithub = async (): Promise<string[]> => {
    const githubApiUrl = `${GITHUB_API_URL}/`;
    isLoadingTemplates = true;
    templatesError = "";

    try {
      const response = await fetch(githubApiUrl, {
        headers: {
          Authorization: `Bearer ${GITHUB_TOKEN}`,
        },
      });

      if (!response.ok) throw new Error(`HTTP ${response.status} - ${response.statusText}`);

      const data = await response.json();

      if (!Array.isArray(data)) {
        throw new Error("No a valid response from GitHub API");
      }

      templates = data
        .filter((item: GithubContentItem) => item.type === "file" && item.name.endsWith(".json"))
        .map((item) => item.name);
      return templates;
    } catch (error: any) {
      templatesError = error.message || "Error fetching templates from GitHub";
      return [];
    } finally {
      isLoadingTemplates = false;
    }
  };

  const fetchTemplate = async (template: string): Promise<ExportedLabelTemplate | undefined> => {
    url.searchParams.set("templateId", template);

    try {
      const response = await fetch(url.toString());
      const data = await response.json();
      return data;
    } catch (error) {}
  };

  const onTemplateSelected = async (template: string) => {
    selectedTemplate = template;
    isLoadingTemplateContent = true;
    templateError = "";
    const nameWithoutExtension = template.replace(/\.json$/, "");

    try {
      const data = await fetchTemplate(nameWithoutExtension);
      if (data) {
        onLoadRequested(data);
      } else {
        templateError = "Template data is undefined.";
      }
    } catch (error: any) {
      templateError = error.message || "Error fetch template";
    } finally {
      isLoadingTemplateContent = false;
    }
  };

  onMount(async () => {
    calcUsedSpace();
  });
</script>

{#if !isEnvConfigured}
  <div class="alert alert-warning d-flex align-items-center gap-2 mb-0" role="alert">
    <MdIcon icon="warning" class="text-warning" />
    <div>
      GitHub template switch is unavailable. Please check your <code>.env</code> configuration.
    </div>
  </div>
{:else}
  <div class="dropdown position-relative">
    <div class="d-flex align-items-center gap-2">
      <button class="btn btn-sm btn-outline-primary d-flex align-items-center gap-2" on:click={openDropdown}>
        <MdIcon icon="cloud_download" />
        <span>Switch template</span>
      </button>
    </div>

    {#if isDropdownOpen}
      <div class="dropdown-menu show saved-labels mt-2" style="display: block;">
        <h6 class="dropdown-header text-wrap text-white">Switch template</h6>

        <div class="px-3">
          {#if isLoading}
            <div class="text-muted small">
              <div class="mx-auto text-center">
                <span class="loader"></span>
              </div>
            </div>
          {:else}
            {#each templates as template}
              <button
                class="btn w-100 mb-2 text-start d-flex align-items-center gap-2 {selectedTemplate == template
                  ? 'btn-warning'
                  : 'btn-primary'}"
                on:click={() => {
                  onTemplateSelected(template);
                  isDropdownOpen = false;
                }}>
                <MdIcon icon="description" />
                <strong>{template}</strong>
              </button>
            {/each}
          {/if}
        </div>
      </div>
    {/if}
  </div>
{/if}

<style>
  .saved-labels.dropdown-menu {
    width: 100vw;
    max-width: 450px;
  }
  .loader {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    display: inline-block;
    border-top: 4px solid #fff;
    border-right: 4px solid transparent;
    box-sizing: border-box;
    animation: rotation 1s linear infinite;
  }
  .loader::after {
    content: "";
    box-sizing: border-box;
    position: absolute;
    left: 0;
    top: 0;
    width: 48px;
    height: 48px;
    border-radius: 50%;
    border-bottom: 4px solid #ff3d00;
    border-left: 4px solid transparent;
  }
  @keyframes rotation {
    0% {
      transform: rotate(0deg);
    }
    100% {
      transform: rotate(360deg);
    }
  }
</style>
