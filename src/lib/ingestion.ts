import { getCmrHost } from '@cumulus/cmr-client/getUrl';
import { postToCMR } from '@cumulus/post-to-cmr';
import * as t from 'io-ts';
import nock from 'nock';

import * as CMA from './cma';
import * as L from './lambda';

export const IngestGranuleProps = t.type({
  config: t.type({
    cmr: t.type({
      cmrEnvironment: t.string,
    }),
  }),
});

export type IngestGranuleProps = t.TypeOf<typeof IngestGranuleProps>;

export const cmrValidate = async (props: IngestGranuleProps) => {
  const { cmrEnvironment } = props.config.cmr;
  const cmrHost = getCmrHost({ cmrEnvironment, cmrHost: undefined });

  // Intercept CMR ingest ("publish") request and mock reply.  This prevents
  // publication, but still allows validation because Cumulus makes a separate CMR
  // validation request, prior to the ingest (publish) request.

  // This is indeed a brittle approach because it not only relies on the fact that the
  // `postToCMR` function explicitly makes a separate validation request, it also uses
  // a library intended for mocking HTTP requests during testing only.

  // The explicit validation request is actually redundant because the ingest request
  // automatically performs validation.  Therefore, `postToCMR` could potentially be
  // modified by removing this redundant validation request, thus breaking our code
  // here that depends on the redundancy, even though `postToCMR` would still work
  // correctly.

  // Ideally, we would avoid reliance on the explicit validation request as well as
  // intercepting the ingest request and simply make a direct CMR validation request
  // ourselves.  However, this brittle approach was chosen for expediency because
  // making a direct validation request has its own downside: it would require copying
  // and pasting much of the implementation of the `postToCMR` function because it
  // includes event-processing logic required to construct the input for the validation
  // request, which is logic that is not decoupled from the `postToCMR` function, and
  // thus not usable without copying it from the source.

  // NOTE: We must allow unmocked requests so that the CMR validation request is passed
  // through.  We want to mock *only* the ingest (publish) request.  Further, since we
  // are mocking an empty response body, we should see a log message produced by
  // `postToCMR` that shows an undefined conceptId value.  If so, mocking succeeded.

  nock(cmrHost, { allowUnmocked: true })
    .put(/ingest/)
    .reply(200, {});

  return await postToCMR(props);
};

// For testing
export const cmrValidateHandler = L.mkAsyncHandler(IngestGranuleProps)(cmrValidate);

// For configuring the AWS Lambda Function
export const cmrValidateCMAHandler = CMA.asyncHandler(cmrValidateHandler);
