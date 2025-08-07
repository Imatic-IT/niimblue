import type { ExportedLabelTemplate } from "../types";

const GITHUB_RAW_URL = import.meta.env.VITE_GITHUB_REPO_RAW_URL;

export const fetchTemplateFromGithub = async (
  template: string
): Promise<ExportedLabelTemplate | null> => {
  const githubRawBaseUrl = `${GITHUB_RAW_URL}/${template}.json`;

  try {
    const response = await fetch(githubRawBaseUrl);

    if (!response.ok) {
      console.warn(`fetchTemplateFromGithub: Status ${response.status}`);
      return null;
    }

    const data: ExportedLabelTemplate = await response.json();
    return data;
  } catch (error) {
    console.error("fetchTemplateFromGithub: Error fetching template", error);
    return null;
  }
};
