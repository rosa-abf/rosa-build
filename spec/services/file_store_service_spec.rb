require 'spec_helper'

describe FileStoreService::File do

  let(:sha1) { 'test-sha1' }

  context '#exist?' do
    let(:response)  { [ { file_name: 'test.log', sha1_hash: sha1 } ].to_json }
    let(:url)       { "http://file-store.rosalinux.ru/api/v1/file_stores.json?hash=#{sha1}" }

    subject { FileStoreService::File.new(sha1: sha1) }

    it 'returns true if file exists' do
      stub_request(:get, url).to_return(body: response)
      expect(subject.exist?).to be_true
    end

    it 'returns false if file does not exist' do
      stub_request(:get, url).to_return(body: '[]')
      expect(subject.exist?).to be_false
    end

    it 'returns false on error' do
      stub_request(:get, url).to_raise(StandardError)
      expect(subject.exist?).to be_false
    end
  end

  context '#save' do
    let(:data) { { path: 'test-path', fullname: 'test-fullname' } }
    let(:file) { double(:file) }

    before do
      allow(Digest::SHA1).to receive(:hexdigest).and_return(sha1)
      allow(File).to receive(:read).and_return(file)
    end

    subject { FileStoreService::File.new(data: data) }

    it 'returns sha1 if file already exists on FS' do
      allow(subject).to receive(:exist?).and_return(true)
      expect(subject.save).to eq sha1
    end

    context 'file does not exist on FS' do
      let(:url) { "http://test-token:@file-store.rosalinux.ru/api/v1/upload" }
      let(:response)  { { sha1_hash: sha1 }.to_json }

      before do
        allow(subject).to receive(:exist?).and_return(false)
        allow(File).to receive(:new).and_return(file)
        allow(subject).to receive(:token).and_return('test-token')
      end

      it 'returns sha1 if response code - 422' do
        stub_request(:post, url).to_raise(RestClient::UnprocessableEntity)
        expect(subject.save).to eq sha1
      end

      it 'returns nil on error' do
        stub_request(:post, url).to_raise(StandardError)
        expect(subject.save).to be_nil
      end

      it 'returns sha1 on success' do
        stub_request(:post, url).to_return(body: response)
        expect(subject.save).to eq sha1
      end
    end
  end

  context '#destroy' do
    let(:url) { "http://file-store.rosalinux.ru/api/v1/file_stores/#{sha1}.json" }

    it 'not raise errors' do
      stub_request(:delete, url).to_raise(StandardError)
      expect {subject.destroy }.to_not raise_error
    end

  end

end
