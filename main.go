package main

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/cobra/doc"
	"github.com/xanzy/go-gitlab"
)

var version = "dev"

// Return first non-empty string
func coalesce(values ...string) string {
	for _, str := range values {
		if str != "" {
			return str
		}
	}
	return ""
}

// Return release by name
func releaseByName(rels []*gitlab.Release, name string) *gitlab.Release {
	if len(rels) == 0 {
		return nil
	}
	if name == "" {
		return rels[0]
	}
	for _, rel := range rels {
		if rel.Name == name {
			return rel
		}
	}
	return nil
}

func main() {
	params := downloadReleaseParams{}

	genMarkdown := ""

	rootCmd := &cobra.Command{
		Use:     "gitlab-download-release",
		Short:   "Download release from Gitlab project",
		Version: version,
		RunE: func(cmd *cobra.Command, args []string) error {
			if genMarkdown != "" {
				if err := doc.GenMarkdownTree(cmd, genMarkdown); err != nil {
					fmt.Println("Error:", err)
					os.Exit(2)
				}
				return nil
			}
			if params.Project == "" {
				return fmt.Errorf("no project provided")
			}
			if err := downloadRelease(params); err != nil {
				fmt.Println("Error:", err)
				os.Exit(2)
			}
			return nil
		},
	}

	rootCmd.Flags().StringVarP(&params.File, "file", "f", "", "`NAME` of asset to download (default is all)")
	rootCmd.Flags().BoolVarP(&params.DryRun, "dry-run", "n", false, "do not download and print what might be downloaded")
	rootCmd.Flags().StringVarP(&params.GitlabTokenEnv, "gitlab-token-env", "t", "GITLAB_TOKEN", "name for environment `VAR` with Gitlab token")
	rootCmd.Flags().StringVarP(&params.GitlabUrl, "gitlab-url", "g", coalesce(os.Getenv("CI_SERVER_URL"), "https://gitlab.com"), "`URL` of the Gitlab instance")
	rootCmd.Flags().BoolVarP(&params.List, "list", "l", false, "list releases or assets or URL of asset rather than download")
	rootCmd.Flags().StringVarP(&params.Project, "project", "p", os.Getenv("CI_PROJECT_ID"), "`PROJECT` with releases")
	rootCmd.Flags().StringVarP(&params.Release, "release", "r", "", "`RELEASE` to download (default is last)")

	rootCmd.Flags().StringVar(&genMarkdown, "gen-markdown", "", "Generate Markdown documentation")

	if err := rootCmd.Flags().MarkHidden("gen-markdown"); err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}

type downloadReleaseParams struct {
	DryRun         bool
	File           string
	GitlabTokenEnv string
	GitlabUrl      string
	List           bool
	Project        string
	Release        string
}

func downloadRelease(params downloadReleaseParams) error {
	gitlabToken := os.Getenv(params.GitlabTokenEnv)

	gl, err := gitlab.NewClient(gitlabToken, gitlab.WithBaseURL(params.GitlabUrl))
	if err != nil {
		return fmt.Errorf("failed to create client: %w", err)
	}

	rels, _, err := gl.Releases.ListReleases(params.Project, &gitlab.ListReleasesOptions{})
	if err != nil {
		return fmt.Errorf("cannot get list of releases for the project %s: %w", params.Project, err)
	}

	if params.List && params.Release == "" {
		for _, rel := range rels {
			fmt.Println(rel.Name)
		}
		return nil
	}

	rel := releaseByName(rels, params.Release)
	if rel == nil {
		return errors.New("no release found")
	}

	assets := rel.Assets
	if len(assets.Links) == 0 {
		return errors.New("release has no downloads in the assets")
	}

	if params.List && params.File == "" {
		for _, link := range assets.Links {
			fmt.Println(link.Name)
		}
		return nil
	}

	dryRunMsg := ""
	if params.DryRun {
		dryRunMsg = " (dry run)"
	}

	for _, link := range assets.Links {
		if params.File != "" && link.Name != params.File {
			continue
		}

		if params.List {
			fmt.Println(link.URL)
			continue
		}

		fmt.Printf("Downloading %s from %s%s\n", link.Name, link.URL, dryRunMsg)

		if params.DryRun {
			continue
		}

		req, err := http.NewRequest("GET", link.URL, nil)
		if err != nil {
			return fmt.Errorf("cannot create HTTP request: %w", err)
		}

		if gitlabToken != "" {
			req.Header.Set("Authorization", "Bearer "+gitlabToken)
		}

		res, err := http.DefaultClient.Do(req)
		if err != nil {
			return fmt.Errorf("cannot download: %w", err)
		}
		defer res.Body.Close()

		file, err := os.Create(link.Name)
		if err != nil {
			return fmt.Errorf("cannot create a file: %w", err)
		}
		defer file.Close()

		_, err = io.Copy(file, res.Body)
		if err != nil {
			return fmt.Errorf("cannot write to file: %w", err)
		}
	}

	return nil
}
