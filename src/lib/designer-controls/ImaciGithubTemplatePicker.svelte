<script lang="ts">
  import { onMount } from "svelte";
  import MdIcon from "../basic/MdIcon.svelte";
  import { type ExportedLabelTemplate } from "../../types";
  import { LocalStoragePersistence } from "../../utils/persistence";
  export let onLoadRequested: (label: ExportedLabelTemplate) => void;
  export let onRequestLabelTemplate: () => ExportedLabelTemplate;

  const GITHUB_TOKEN = import.meta.env.VITE_IMATIC_GITHUB_TOKEN;
  const GITHUB_API_URL = import.meta.env.VITE_GITHUB_REPO_API_URL;
  const GITHUB_RAW_URL = import.meta.env.VITE_GITHUB_REPO_RAW_URL;

  const isEnvConfigured = Boolean(GITHUB_TOKEN) && Boolean(GITHUB_API_URL) && Boolean(GITHUB_RAW_URL);

  let usedSpace: number = 0;
  let isDropdownOpen = false;
  let isLoading = false;

  let isSavingAsNew = false;
  let newTemplateName = "";
  let templates: string[] = [];
  let selectedTemplate: string | null = null;
  let isLoadingTemplates = false;
  let templatesError = "";
  let isLoadingTemplateContent = false;
  let templateError = "";

  async function openDropdown() {
    isDropdownOpen = true;
    isLoading = true;
    await fetchTemplatesFromGithub();
    isLoading = false;
  }

  interface GithubContentItem {
    type: string;
    name: string;
  }

  const calcUsedSpace = () => {
    usedSpace = LocalStoragePersistence.usedSpace();
  };

  async function pushTemplateToGithub(fileName: string, commitMessage = "Added new template", isNew = false) {
    const path = fileName.endsWith(".json") ? fileName : `${fileName}.json`;
    const apiUrl = `${GITHUB_API_URL}/${path}`;
    const fileContentBase64 = btoa(unescape(encodeURIComponent(JSON.stringify(onRequestLabelTemplate(), null, 2))));

    let sha: string | undefined = undefined;

    if (!isNew) {
      try {
        const existingFile = await fetch(apiUrl, {
          headers: {
            Authorization: `Bearer ${GITHUB_TOKEN}`,
            Accept: "application/vnd.github.v3+json",
          },
        });

        if (existingFile.ok) {
          const existingData = await existingFile.json();
          sha = existingData.sha;
        }
      } catch (e) {
        console.warn("File probably does not exist yet:", path);
      }
    }

    const body = {
      message: commitMessage,
      content: fileContentBase64,
      ...(sha ? { sha } : {}),
    };

    const response = await fetch(apiUrl, {
      method: "PUT",
      headers: {
        Authorization: `Bearer ${GITHUB_TOKEN}`,
        Accept: "application/vnd.github.v3+json",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`GitHub push failed: ${error.message}`);
    }

    const data = await response.json();

    return data;
  }

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
    const githubRawBaseUrl = `${GITHUB_RAW_URL}/${template}`;

    try {
      const reponse = await fetch(githubRawBaseUrl);
      const data = await reponse.json();
      return data;
    } catch (error) {}
  };

  const onTemplateSelected = async (template: string) => {
    selectedTemplate = template;
    isLoadingTemplateContent = true;
    templateError = "";
    try {
      const data = await fetchTemplate(selectedTemplate);
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

  function startSaveAsNew() {
    isSavingAsNew = true;
    newTemplateName = selectedTemplate ? selectedTemplate.replace(/\.json$/, "") + "-copy" : "";
  }

  async function confirmSaveAsNew() {
    if (!newTemplateName.trim()) {
      alert("Please enter a valid template name.");
      return;
    }
    try {
      await pushTemplateToGithub(newTemplateName + ".json", `Created new template ${newTemplateName}`, true);
      isSavingAsNew = false;
      newTemplateName = "";
    } catch (error) {
      alert(`Saving new template failed`);
    }
  }

  function cancelSaveAsNew() {
    isSavingAsNew = false;
    newTemplateName = "";
  }

  onMount(async () => {
    calcUsedSpace();
  });
</script>


{#if !isEnvConfigured}
  <div class="alert alert-warning d-flex align-items-center gap-2 mb-0" role="alert">
    <MdIcon icon="warning" class="text-warning" />
    <div>
      GitHub template import is unavailable. Please check your <code>.env</code> configuration.
    </div>
  </div>
{:else}
<div class="dropdown position-relative">
  <div class="d-flex flex-column gap-2">
    <!-- Load base template -->
    <button class="btn btn-sm btn-outline-primary d-flex align-items-center gap-2" on:click={openDropdown}>
      <MdIcon icon="cloud_download" />
      <span>Load base template From Github</span>
    </button>

    {#if selectedTemplate && !isSavingAsNew}
      <button
        class="btn btn-sm btn-primary d-flex align-items-center gap-2"
        on:click={() => selectedTemplate && pushTemplateToGithub(selectedTemplate, `Updated ${selectedTemplate}`)}>
        <MdIcon icon="cloud_upload" />
        <span>Push to GitHub</span>
      </button>

      <button class="btn btn-sm btn-outline-secondary d-flex align-items-center gap-2" on:click={startSaveAsNew}>
        <MdIcon icon="save_as" />
        <span>Save as new template</span>
      </button>
    {/if}

    {#if isSavingAsNew}
      <input
        type="text"
        class="form-control form-control-sm"
        bind:value={newTemplateName}
        placeholder="New template filename (without .json)"
        on:keydown={(e) => e.key === "Enter" && confirmSaveAsNew()} />

      <button class="btn btn-sm btn-success" on:click={confirmSaveAsNew}>Save</button>
      <button class="btn btn-sm btn-secondary" on:click={cancelSaveAsNew}>Cancel</button>
    {/if}
  </div>

  {#if isDropdownOpen}
    <div class="dropdown-menu show saved-labels mt-2" style="display: block;">
      <h6 class="dropdown-header text-wrap text-white">
        Import <a href="https://github.com/Imatic-IT/niimblue-templates">Github</a> template
      </h6>

      <div class="alert alert-warning py-2 px-2 small mb-2 mx-3">
        This action fetches sample label templates from GitHub for preview and editing purposes.<br /><br />
        <strong>Note:</strong> After saving a template, it may take a few seconds for the changes to appear here due to GitHub's
        internal processing delay.
      </div>

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
              class="btn btn-primary w-100 mb-2 text-start d-flex align-items-center gap-2"
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
