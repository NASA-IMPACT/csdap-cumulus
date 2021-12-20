declare module '@cumulus/post-to-cmr' {
  type Granule = {
    readonly granuleId: string;
  };

  function postToCMR(
    event: unknown
  ): Promise<{ readonly granules: readonly Granule[] }>;
}
