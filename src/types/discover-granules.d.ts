declare module '@cumulus/discover-granules' {
  type Granule = {
    readonly granuleId: string;
  };

  function discoverGranules(
    event: unknown
    // eslint-disable-next-line functional/prefer-readonly-type
  ): Promise<{ readonly granules: readonly { granuleId: string }[] }>;
}
