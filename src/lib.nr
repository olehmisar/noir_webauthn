pub global SIGNATURE_LEN: u32 = 64;

pub fn verify_signature<let CLIENT_DATA_JSON_MAX_LEN: u32, let AUTHENTICATOR_DATA_MAX_LEN: u32>(
    public_key_x: [u8; 32],
    public_key_y: [u8; 32],
    signature: [u8; SIGNATURE_LEN],
    client_data_json: BoundedVec<u8, CLIENT_DATA_JSON_MAX_LEN>,
    authenticator_data: BoundedVec<u8, AUTHENTICATOR_DATA_MAX_LEN>,
    challenge: [u8; 32],
    challenge_index: u32,
) -> bool {
    let client_data_json_hash = nodash::sha256(client_data_json);
    let concatenated: BoundedVec<u8, AUTHENTICATOR_DATA_MAX_LEN + 32> =
        concat(authenticator_data, client_data_json_hash);
    let hashed_message = nodash::sha256(concatenated);

    let challenge_base64_url: [u8; 43] = base64::BASE64_URL_ENCODER::encode(challenge);
    str_contains_base64_url(
        client_data_json.storage(),
        challenge_base64_url,
        challenge_index,
    );

    let verification = std::ecdsa_secp256r1::verify_signature(
        public_key_x,
        public_key_y,
        signature,
        hashed_message,
    );
    verification
}

fn str_contains_base64_url<let N: u32, let H: u32>(haystack: [u8; H], needle: [u8; N], index: u32) {
    for i in 0..needle.len() {
        if (needle[i] != 61) {
            // ignore padding (61 is '=')
            assert(haystack[index + i] == needle[i]);
        }
    }
}

fn concat<let N: u32>(a: BoundedVec<u8, N>, b: [u8; 32]) -> BoundedVec<u8, N + 32> {
    let mut result = [0 as u8; N + 32];
    let mut j = 0;
    for i in 0..N {
        if (i < a.len()) {
            result[j] = a.get(i);
            j += 1;
        }
    }
    for i in 0..b.len() {
        result[j] = b[i];
        j += 1;
    }
    BoundedVec::from_parts(result, j)
}

mod tests {
    use super::{SIGNATURE_LEN, verify_signature};

    global AUTHENTICATOR_DATA_MAX_LEN: u32 = 64;
    global CLIENT_DATA_JSON_MAX_LEN: u32 = 256;
    fn ver(
        public_key_x: [u8; 32],
        public_key_y: [u8; 32],
        signature: [u8; SIGNATURE_LEN],
        client_data_json: BoundedVec<u8, CLIENT_DATA_JSON_MAX_LEN>,
        authenticator_data: BoundedVec<u8, AUTHENTICATOR_DATA_MAX_LEN>,
        challenge: [u8; 32],
        challenge_index: u32,
    ) -> bool {
        verify_signature(
            public_key_x,
            public_key_y,
            signature,
            client_data_json,
            authenticator_data,
            challenge,
            challenge_index,
        )
    }

    #[test]
    fn my_test() {
        assert(ver(
            [
                91, 200, 36, 72, 14, 85, 105, 189, 204, 19, 185, 157, 161, 241, 56, 107, 228, 8, 67,
                156, 7, 183, 173, 111, 146, 216, 51, 2, 244, 251, 78, 203,
            ],
            [
                30, 52, 243, 79, 92, 114, 5, 253, 138, 212, 14, 51, 122, 247, 225, 82, 193, 243,
                157, 70, 225, 62, 254, 206, 247, 110, 252, 111, 188, 128, 142, 226,
            ],
            [
                47, 222, 74, 22, 26, 2, 142, 123, 25, 179, 68, 61, 58, 204, 200, 245, 241, 176, 227,
                237, 173, 115, 147, 229, 128, 165, 63, 170, 148, 250, 171, 141, 115, 50, 249, 181,
                84, 62, 116, 119, 139, 101, 89, 14, 140, 246, 186, 29, 143, 146, 13, 198, 186, 85,
                47, 213, 235, 176, 236, 26, 88, 231, 191, 129,
            ],
            BoundedVec::from([
                123, 34, 116, 121, 112, 101, 34, 58, 34, 119, 101, 98, 97, 117, 116, 104, 110, 46,
                103, 101, 116, 34, 44, 34, 99, 104, 97, 108, 108, 101, 110, 103, 101, 34, 58, 34,
                85, 76, 76, 69, 80, 57, 79, 82, 66, 114, 114, 55, 117, 103, 50, 106, 84, 56, 81,
                119, 52, 102, 107, 101, 80, 74, 98, 113, 75, 115, 55, 105, 118, 68, 81, 82, 110, 53,
                75, 122, 100, 49, 65, 34, 44, 34, 111, 114, 105, 103, 105, 110, 34, 58, 34, 104,
                116, 116, 112, 58, 47, 47, 108, 111, 99, 97, 108, 104, 111, 115, 116, 58, 53, 49,
                56, 52, 34, 44, 34, 99, 114, 111, 115, 115, 79, 114, 105, 103, 105, 110, 34, 58,
                102, 97, 108, 115, 101, 125,
            ]),
            BoundedVec::from([
                73, 150, 13, 229, 136, 14, 140, 104, 116, 52, 23, 15, 100, 118, 96, 91, 143, 228,
                174, 185, 162, 134, 50, 199, 153, 92, 243, 186, 131, 29, 151, 99, 29, 0, 0, 0, 0,
            ]),
            [
                80, 178, 196, 63, 211, 145, 6, 186, 251, 186, 13, 163, 79, 196, 48, 225, 249, 30,
                60, 150, 234, 42, 206, 226, 188, 52, 17, 159, 146, 179, 119, 80,
            ],
            36,
        ));
    }

    #[test]
    fn test_fail() {
        assert(
            !ver(
                [
                    90, 200, 36, 72, 14, 85, 105, 189, 204, 19, 185, 157, 161, 241, 56, 107, 228, 8,
                    67, 156, 7, 183, 173, 111, 146, 216, 51, 2, 244, 251, 78, 203,
                ],
                [
                    30, 52, 243, 79, 92, 114, 5, 253, 138, 212, 14, 51, 122, 247, 225, 82, 193, 243,
                    157, 70, 225, 62, 254, 206, 247, 110, 252, 111, 188, 128, 142, 226,
                ],
                [
                    47, 222, 74, 22, 26, 2, 142, 123, 25, 179, 68, 61, 58, 204, 200, 245, 241, 176,
                    227, 237, 173, 115, 147, 229, 128, 165, 63, 170, 148, 250, 171, 141, 115, 50,
                    249, 181, 84, 62, 116, 119, 139, 101, 89, 14, 140, 246, 186, 29, 143, 146, 13,
                    198, 186, 85, 47, 213, 235, 176, 236, 26, 88, 231, 191, 129,
                ],
                BoundedVec::from([
                    123, 34, 116, 121, 112, 101, 34, 58, 34, 119, 101, 98, 97, 117, 116, 104, 110,
                    46, 103, 101, 116, 34, 44, 34, 99, 104, 97, 108, 108, 101, 110, 103, 101, 34,
                    58, 34, 85, 76, 76, 69, 80, 57, 79, 82, 66, 114, 114, 55, 117, 103, 50, 106, 84,
                    56, 81, 119, 52, 102, 107, 101, 80, 74, 98, 113, 75, 115, 55, 105, 118, 68, 81,
                    82, 110, 53, 75, 122, 100, 49, 65, 34, 44, 34, 111, 114, 105, 103, 105, 110, 34,
                    58, 34, 104, 116, 116, 112, 58, 47, 47, 108, 111, 99, 97, 108, 104, 111, 115,
                    116, 58, 53, 49, 56, 52, 34, 44, 34, 99, 114, 111, 115, 115, 79, 114, 105, 103,
                    105, 110, 34, 58, 102, 97, 108, 115, 101, 125,
                ]),
                BoundedVec::from([
                    73, 150, 13, 229, 136, 14, 140, 104, 116, 52, 23, 15, 100, 118, 96, 91, 143,
                    228, 174, 185, 162, 134, 50, 199, 153, 92, 243, 186, 131, 29, 151, 99, 29, 0, 0,
                    0, 0,
                ]),
                [
                    80, 178, 196, 63, 211, 145, 6, 186, 251, 186, 13, 163, 79, 196, 48, 225, 249,
                    30, 60, 150, 234, 42, 206, 226, 188, 52, 17, 159, 146, 179, 119, 80,
                ],
                36,
            ),
        );
    }

    #[test]
    fn some_test() {
        assert(ver(
            [
                139, 86, 118, 230, 15, 13, 30, 204, 6, 133, 248, 82, 54, 101, 178, 189, 126, 170,
                84, 48, 0, 106, 149, 40, 133, 99, 30, 73, 2, 210, 205, 200,
            ],
            [
                184, 8, 42, 248, 97, 207, 125, 175, 201, 50, 10, 102, 148, 60, 53, 169, 208, 70,
                112, 255, 179, 218, 110, 33, 33, 135, 156, 9, 30, 230, 17, 26,
            ],
            [
                182, 153, 194, 137, 148, 109, 190, 71, 178, 33, 99, 179, 75, 12, 9, 132, 225, 154,
                15, 237, 58, 248, 132, 130, 94, 16, 155, 206, 77, 21, 66, 223, 79, 248, 19, 205, 57,
                183, 65, 109, 45, 135, 165, 109, 50, 56, 84, 208, 76, 252, 111, 240, 6, 114, 169,
                202, 193, 130, 20, 17, 144, 51, 55, 254,
            ],
            BoundedVec::from_parts(
                [
                    123, 34, 116, 121, 112, 101, 34, 58, 34, 119, 101, 98, 97, 117, 116, 104, 110,
                    46, 103, 101, 116, 34, 44, 34, 99, 104, 97, 108, 108, 101, 110, 103, 101, 34,
                    58, 34, 67, 70, 99, 69, 97, 110, 104, 100, 102, 45, 57, 74, 106, 84, 51, 48, 89,
                    100, 116, 98, 78, 87, 54, 53, 81, 117, 88, 52, 85, 84, 80, 57, 79, 118, 122, 66,
                    85, 97, 74, 95, 87, 111, 111, 34, 44, 34, 111, 114, 105, 103, 105, 110, 34, 58,
                    34, 104, 116, 116, 112, 58, 47, 47, 108, 111, 99, 97, 108, 104, 111, 115, 116,
                    58, 53, 49, 56, 52, 34, 44, 34, 99, 114, 111, 115, 115, 79, 114, 105, 103, 105,
                    110, 34, 58, 102, 97, 108, 115, 101, 125, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0,
                ],
                134,
            ),
            BoundedVec::from_parts(
                [
                    73, 150, 13, 229, 136, 14, 140, 104, 116, 52, 23, 15, 100, 118, 96, 91, 143,
                    228, 174, 185, 162, 134, 50, 199, 153, 92, 243, 186, 131, 29, 151, 99, 29, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0,
                ],
                37,
            ),
            [
                8, 87, 4, 106, 120, 93, 127, 239, 73, 141, 61, 244, 97, 219, 91, 53, 110, 185, 66,
                229, 248, 81, 51, 253, 58, 252, 193, 81, 162, 127, 90, 138,
            ],
            36,
        ));
    }
}
